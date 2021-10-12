#!/usr/bin/python3
import os
import sys, getopt
from mailmerge import MailMerge
import xml.etree.cElementTree as ET
import gspread
from oauth2client.service_account import ServiceAccountCredentials
import json
from pathlib import Path
import pandas as pd

def main(argv):
    wordtemp = ''
    xmlfile = ''
    outdir = ''
    try:
        opts, args = getopt.getopt(argv,"hw:x:o:",["wtemp=","xinput=","odir="])
    except getopt.GetoptError:
        print ('populate-word-template.py -w <word-template> -x <xml-input> -o <output-dir>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print ('populate-word-template.py -w <word-template> -x <xml-input> -o <output-dir>')
            sys.exit()
        elif opt in ("-w", "--wtemp"):
            wordtemp = arg
        elif opt in ("-x", "--xinput"):
            xmlfile = arg
        elif opt in ("-o", "--odir"):
            outdir = arg
    #print ('Word template is', wordtemp)
    #print ('XML input file is', xmlfile)
    #print ('Output directory is', outdir)

    tree = ET.parse(xmlfile)
    root = tree.getroot()
    ucode=root.find(".//AT-id").text
    uname=root.find(".//AT-name[@lang='en']").text
    sname=root.find(".//AT-short-name").text
    asm_info={'unit_name':uname,
    'unit_code': ucode,
    'summary':root.find('.//AT-description').text,
    'biota':root.find('.//Biota-Summary').text,
    'abiotic':root.find('.//Abiotic-Summary').text,
    'biotic':root.find('.//Processes-Summary').text,
    'threats':root.find('.//Threats-Summary').text,
    'distribution':root.find('.//Distribution-Summary').text,
    'collapse_spatial':root.find('.//Spatial-collapse').text,
    'collapse_functional':root.find('.//Functional-collapse').text}
    ref_dict = []
    for reference in root.findall('.//Reference'):
        ref_dict.append({'references':reference.text})

    scopes = [
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/drive'
    ]
    #access the json key
    apicrds = Path.home() / ".secrets" / "googlecloud/agile-tangent-319108-f34acd053909.json"
    credentials = ServiceAccountCredentials.from_json_keyfile_name(apicrds, scopes)
    file = gspread.authorize(credentials) # authenticate the JSON key with gspread
    sheet = file.open("Mangroves in IUCN GET level 4 units - species and threats")  #open sheet
    kmgv = sheet.worksheet('Key Mangrove spp')
    df = pd.DataFrame(kmgv.get_all_records())
    ss=df[df[sname].eq("TRUE")].sort_values(by=['class','order_','family','binomial'])
    ksp = ss[['class', 'order_','family', 'binomial', 'IUCN RLTS category']]
    ksp = ksp.rename(columns={"class":"key_class","order_":"key_order","family":"key_family","binomial":"key_species","IUCN RLTS category":"key_category"})
    amgv = sheet.worksheet('Other spp. assoc with Mangroves')
    df = pd.DataFrame(amgv.get_all_records())
    ss=df[~df[sname].eq("")].sort_values(by=['kingdom_name', 'phylum_name','class_name','order_name','family_name','genus_name'])
    tgt = ss[['class_name', 'order_name','family_name', 'scientific_name', 'taxonomic_authority','RLTS category', 'main_common_name', 'season']]
    tgt = tgt.rename(columns={"class_name":"assoc_class","order_name":"assoc_order","family_name":"assoc_family","scientific_name":"assoc_species","taxonomic_authority":"assoc_author", "RLTS category":"assoc_category", "main_common_name":"assoc_common","season":"assoc_season"})
    assoc_table = tgt.to_dict('records')
    key_table = ksp.to_dict('records')

    document = MailMerge(wordtemp)
    #print(document.get_merge_fields())
    document.merge(**asm_info)
    document.merge_rows('assoc_class', assoc_table)
    document.merge_rows('key_class', key_table)
    document.merge_rows('references', ref_dict )
    outfile=ucode+'-'+uname+'.docx'
    with open(Path(outdir) / outfile, "wb") as f:
        document.write(f)


if __name__ == "__main__":
    main(sys.argv[1:])

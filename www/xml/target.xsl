<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="Assessment-Target">
<html>
    <head>
        <title>MFT1.2 level 4 units (example)</title>
        <link rel="stylesheet" href="https://www.w3schools.com/w3css/4/w3.css"/>

        <style type="text/css">
        body {
            margin:10px;
            background-color:#EEE3E3;
            font-family:verdana,helvetica,sans-serif;
        }

        .tutorial-name {
            display:block;
            font-weight:bold;
        }

        .tutorial-url {
            display:block;
            color:#6E0D25;
            font-size:small;
            font-style:italic;
        }
        .summary-text {
            display:block;
            background-color:#F1EBE4;
            color:#6E0D25;
            font-size:small;
        }
        div.threats {
            display:block;
            background-color:#C39EA0;
            font-size:small;
            margin-left: 10%;
            width:80%;
        }
        span.level1 {
            display:block;
            color:#636363;
            font-size:small;
            font-style:italic;
            margin-left: 10px;
        }
        span.level2 {
            display:block;
            color:#636363;
            font-size:small;
            font-style:italic;
            margin-left: 20px;
        }
        span.level3 {
            display:block;
            color:#636363;
            font-size:small;
            font-style:italic;
            margin-left: 30px;
        }
        span.level4 {
            display:block;
            color:#636363;
            font-size:small;
            font-style:italic;
            margin-left: 40px;
        }
        </style>

      <script type="text/javascript" src="target.js"></script>


    </head>
    <body>
        <h2>Assessment units: Regional ecosystem subgroups</h2>
          <p class="tutorial-url"><xsl:value-of select="AT-id"/></p>

          <xsl:for-each select="AT-names/AT-name">
            <span class="tutorial-name"><xsl:value-of select="."/> (<xsl:value-of select="@lang"/>) <xsl:element name="br"/></span>
          </xsl:for-each>

          <h4>Summary</h4>
          <span class="summary-text"><xsl:value-of select="AT-descriptions/AT-description"/></span>

          <div class="w3-bar w3-black">
            <button class="w3-bar-item w3-button" onclick="openCity('Classification')">Ecosystem classification</button>
            <button class="w3-bar-item w3-button" onclick="openCity('Biota')">Characteristic Biota</button>
            <button class="w3-bar-item w3-button" onclick="openCity('Abiotic')">Abiotic envrionment</button>
            <button class="w3-bar-item w3-button" onclick="openCity('Biotic')">Biotic processes</button>
            <button class="w3-bar-item w3-button" onclick="openCity('Collapse')">Collapse definitions</button>
            <button class="w3-bar-item w3-button" onclick="openCity('Services')">Ecosystem services</button>
            <button class="w3-bar-item w3-button" onclick="openCity('Threats')">Threats</button>
          </div>
          <xsl:apply-templates/>
    </body>
</html>
</xsl:template>

<xsl:template match="AT-names">
  </xsl:template>

  <xsl:template match="AT-id">
    </xsl:template>

<xsl:template match="AT-description">
</xsl:template>

<xsl:template match="Classifications">
  <div id="Classification" class="w3-container city" style="display:none">
    <h4>Ecosystem classifications</h4>
      <xsl:apply-templates/>
    </div>
</xsl:template>

<xsl:template match="Collapse-definition">
  <div id="Collapse" class="w3-container city" style="display:none">
  <h4>Collapse definitions</h4>
    <span class="summary-text"><xsl:value-of select="Spatial-collapse-definitions/Spatial-collapse"/></span>
    <span class="summary-text"><xsl:value-of select="Functional-collapse-definitions/Functional-collapse"/></span>
  </div>
</xsl:template>

<xsl:template match="Biota-Summary">
  <div id="Biota" class="w3-container city" style="display:none">
    <h4>Characteristic biota</h4>
    <span class="summary-text"><xsl:value-of select="."/></span>
  </div>
  </xsl:template>

<xsl:template match="Abiotic-Summary">
  <div id="Abiotic" class="w3-container city" style="display:none">
  <h4>Abiotic</h4>
    <span class="summary-text"><xsl:value-of select="."/></span>
  </div>
</xsl:template>

<xsl:template match="Processes-Summary">
  <div id="Biotic" class="w3-container city" style="display:none">
  <h4>Biotic processes</h4>
    <span class="summary-text"><xsl:value-of select="."/></span>
    </div>
</xsl:template>

<xsl:template match="Services-Summary">
  <div id="Services" class="w3-container city" style="display:none">

  <h4>Ecosystem services</h4>
    <span class="summary-text"><xsl:value-of select="."/></span>
  </div>
</xsl:template>

<xsl:template match="Threats">
  <div id="Threats" class="w3-container city" style="display:none">

  <h4>Threats</h4>
    <xsl:apply-templates/>
  </div>
</xsl:template>



<xsl:template match="Threats-Summaries">
  <span class="summary-text"><xsl:value-of select="Threats-Summary"/></span>
</xsl:template>

<xsl:template match="Threat">
  <div class="threats">
  <p><strong><xsl:value-of select="Threat-name"/></strong>: <xsl:value-of select="Threat-description"/></p>
  <xsl:for-each select="Threat-classification/Threat-classification-element">
    <span class="tutorial-url"><xsl:value-of select="."/><xsl:element name="br"/></span>
  </xsl:for-each>
</div>
</xsl:template>


<xsl:template match="Classification-system">
    <span class="tutorial-url"><strong><xsl:value-of select="@id"/></strong> (version <xsl:value-of select="@version"/>)<xsl:element name="br"/></span>
  <div class="threats">
  <xsl:for-each select="Classification-element">
    <xsl:choose>
      <xsl:when test="@level = '1'">
            <span class="level1"><xsl:value-of select="."/><xsl:element name="br"/></span>
      </xsl:when>
      <xsl:when test="@level = '2'">
            <span class="level2"><xsl:value-of select="."/><xsl:element name="br"/></span>
      </xsl:when>
      <xsl:when test="@level = '3'">
            <span class="level3"><xsl:value-of select="."/><xsl:element name="br"/></span>
      </xsl:when>
      <xsl:otherwise>
            <span class="level4"><xsl:value-of select="."/><xsl:element name="br"/></span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
</div>
</xsl:template>


</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="text"/>
    
    <xsl:template match="/">
        <xsl:apply-templates select="/" mode="M0"/>
    </xsl:template>
    
    <xsl:template match="order_authorizations" priority="4000" mode="M0">
        <bibble/>
        <xsl:choose>
            <xsl:when test="order_authorization"/>
            <xsl:otherwise>In pattern [none]: order_authorizations element must contain at least one 'order_authorization' element.</xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates mode="M0"/>
    </xsl:template>
    
    <xsl:template match="order_authorization" priority="3999" mode="M0">
        <bibble/>
        <xsl:choose>
            <xsl:when test="tttaddress"/>
            <xsl:otherwise>In pattern [none]: Each order_authorization must contain and address element.
            </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates mode="M0"/>
    </xsl:template>
    
    <xsl:template match="text()" priority="-1" mode="M0"/>
</xsl:stylesheet>

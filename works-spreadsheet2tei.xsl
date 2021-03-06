<?xml version="1.0" encoding="UTF-8"?>
<?xml-model href="http://www.tei-c.org/release/xml/tei/custom/schema/relaxng/tei_all.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:syriaca="http://syriaca.org"
    xmlns:lawd="http://lawd.info/ontology/" xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:saxon="http://saxon.sf.net/" xmlns:functx="http://www.functx.com">

    <!-- FORMAT OF COMMENTS -->
    <!-- ??? Indicates an issue that needs resolving. -->
    <!-- ALL CAPS is a section header. -->
    <!-- !!! Shows items that may need to be changed/customized when running this template on a new spreadsheet. -->
    <!-- lower case comments explain the code -->

    <!-- FILE OUTPUT PROCESSING -->
    <!-- specifies how the output file will look -->
    <xsl:output encoding="UTF-8" indent="yes" method="xml" name="xml"/>

    <!-- ??? Not sure what these variables do. They're from Winona's saints XSL. -->
    <xsl:variable name="n">
        <xsl:text/>
    </xsl:variable>
    <xsl:variable name="s">
        <xsl:text> </xsl:text>
    </xsl:variable>

    <!-- COLUMN MAPPING FROM INPUT SPREADSHEET -->
    <!-- !!! When modifying this stylesheet for a new spreadsheet, you should (in most cases) only need to  
            1. name your columns according to the conventions here (https://docs.google.com/spreadsheets/d/1_uilPEx2XFU8dlsTx2O8B1itZZL3CrCxMBaiS1eKofU/edit?usp=sharing) 
                or change the contents of the $column-mapping variable below manually to use the column names from your spreadsheet with appropriate attributes,
            2. change the TEI header information, 
            3. change the $directory (optional), and
            4. add to the column-mapping and bibls TEMPLATES any attributes that we haven't used before. 
            NB: * Each cell in the spreadsheet must contain data from only one source.
                * The spreadsheet must contain a column named "New_URI". This column should not be "mapped" below; it is hard-coded into the stylesheet.
                * A bibl_ana column is also hard-coded into the stylesheet, but is not required. The values in this column determine what (if anything) goes into the work/@ana attribute,
                and which series statements are used.
                * Each record should have at least one column marked with syriaca-tags="#syriaca-headword", otherwise it will be placed into the "incomplete" folder.
                * It's fine to map multiple spreadsheets below, as long as they don't contain columns with the same names but different attributes (e.g., @source or @xml:lang). 
                * Columns for <sex> element will go into the @value. If they contain the abbreviations "M" or "F", then "male" or "female" will be inserted into the element content.
                * The column-mapping template (see below) defines content of the <state> element as nested inside <desc> (needed for valid TEI) -->
    <xsl:variable name="column-mapping">
        <!-- This variable contains a set of pseudo-TEI nodes that have TEI element names and attributes, plus an @column specifying the name or position of 
             the spreadsheet column that contains the data that should be put into those TEI elements and a @sourceUriColumn specifying the name of the column that contains 
             the bibl URI of this column's source.
             For example, <persName xml:lang="syr" sourceUriColumn="Source 2" column="3"/> -->

        <!-- AUTOMATIC COLUMN MAPPING -->
        <!-- column mapping using the column nameing conventions. Format for column name is "elementName attributeValueOrType.sourceColumnName.languageCode" 
             See https://docs.google.com/spreadsheets/d/1_uilPEx2XFU8dlsTx2O8B1itZZL3CrCxMBaiS1eKofU/edit?usp=sharing -->
        <!-- uses the first row to define columns -->
        <xsl:for-each select="/root/row[1]/*">
            <!-- uses the column name to find out which element name and attributes it should use -->
            <xsl:variable name="column-info" select="syriaca:column-name(name())"/>
            <!--            <xsl:variable name="test-element-name" select="$column-info/*[1]"/>-->
            <!--<xsl:if
                test="$column-info/elementName=('persName' or 'sex' or 'state' or 'birth' or 'death' or 'floruit' or 'citedRange' or 'idno' or 'relation' or 'note' or 'trait') and $column-info/attributeValueOrType!=('when' or 'notBefore' or 'notAfter')">
-->
            <xsl:variable name="element-name" as="xs:string">
                <!-- chooses the name for the TEI element, based on the part of the column name before any (_) or (.). -->
                <!-- !!! If you want to add another type of TEI element, you should add it here and also in the main ("/root") template under 
                        TEI/text/body/bibl (see format there). If the default behavior of placing the column contents directly inside this element 
                        is not adequate, you should also modify the column-mapping template below. -->
                <xsl:choose>
                    <xsl:when test="matches(name(), '^title[\._]')">title</xsl:when>
                    <xsl:when test="matches(name(), '^author_ref')">author</xsl:when>
                    <xsl:when test="matches(name(), '^editor_ref')">editor</xsl:when>
                    <xsl:when test="matches(name(), '^date\.')">date</xsl:when>
                    <xsl:when test="matches(name(), '^citedRange[\._]')">citedRange</xsl:when>
                    <xsl:when test="matches(name(), '^bibl-note[\._]')">bibl-note</xsl:when>
                    <xsl:when test="matches(name(), '^lang[\._]')">lang</xsl:when>
                    <xsl:when test="matches(name(), '^witnesses[\._]')">witnesses</xsl:when>
                    <xsl:when test="matches(name(), '^cites[\._]')">cites</xsl:when>
                    <xsl:when test="matches(name(), '^idno[\._]')">idno</xsl:when>
                    <xsl:when test="matches(name(), '^relation[\._]')">relation</xsl:when>
                    <xsl:when test="matches(name(), '^note[\._]')">note</xsl:when>
                    <xsl:when test="matches(name(), '^extent[\._]')">extent</xsl:when>
                    <!-- a non-empty string is required in this variable type, thus "none" -->
                    <xsl:otherwise>none</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="lang-regex"
                select="'\.([a-z]{2,3}((\-[A-Z][a-z]{3})|(\-x\-[a-z]+))?)$'"/>
            <xsl:if test="$element-name != 'none'">
                <xsl:element name="{$element-name}">
                    <!-- adds @xml:lang using the codes at the end of the column name (after the final dot). -->
                    <xsl:if test="matches(name(), $lang-regex)">
                        <xsl:attribute name="xml:lang"
                            select="replace(name(), concat('.*', $lang-regex), '$1')"/>
                    </xsl:if>
                    <!-- adds @type based on the text immediately following the element name -->
                    <!-- !!! Add any additional types you need here. -->
                    <xsl:choose>
                        <xsl:when test="matches(name(), '^[a-zA-Z]*_abstract')">
                            <xsl:attribute name="type" select="'abstract'"/>
                        </xsl:when>
                        <xsl:when test="matches(name(), '^[a-zA-Z]*_incipit')">
                            <xsl:attribute name="type" select="'incipit'"/>
                        </xsl:when>
                        <xsl:when test="matches(name(), '^[a-zA-Z]*_explicit')">
                            <xsl:attribute name="type" select="'explicit'"/>
                        </xsl:when>
                        <xsl:when test="matches(name(), '^[a-zA-Z]*_excerpt')">
                            <xsl:attribute name="type" select="'excerpt'"/>
                        </xsl:when>
                        <xsl:when test="matches(name(), '^[a-zA-Z]*_prologue')">
                            <xsl:attribute name="type" select="'prologue'"/>
                        </xsl:when>
                        <xsl:when test="matches(name(), '^[a-zA-Z]*_final-rubric')">
                            <xsl:attribute name="type" select="'final-rubric'"/>
                        </xsl:when>
                        <xsl:when test="matches(name(), '^[a-zA-Z]*_abbreviation')">
                            <xsl:attribute name="type" select="'abbreviation'"/>
                        </xsl:when>
                        <xsl:when test="starts-with(name(), 'idno_')">
                            <xsl:attribute name="type" select="substring-after(name(), 'idno_')"/>
                        </xsl:when>
                    </xsl:choose>
                    <xsl:attribute name="column" select="name()"/>
                    <!-- adds @unit, based on the part of the column name immediately after the element name. -->
                    <!-- ??? does not yet support @target -->
                    <xsl:if test="starts-with(name(), 'citedRange_')">
                        <xsl:attribute name="unit"
                            select="replace(replace(name(), 'citedRange_', ''), '\..*$', '')"/>
                    </xsl:if>
                    <!-- adds @when, @notBefore, @notAfter attributes to date columns -->
                    <!-- ??? dates for state not supported yet. -->
                    <!-- !!! You can add more date-type elements here. -->
                    <xsl:if test="matches(name(), '^date\.')">
                        <xsl:variable name="date-type">
                            <!-- captures the type of element -->
                            <xsl:choose>
                                <xsl:when test="matches(name(), '^date\.')">date</xsl:when>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="date-source">
                            <!-- captures the name of the source column this column is using, to use when constructing the machine-readable date attribute columns below -->
                            <xsl:analyze-string select="name()" regex="Source_[0-9]+">
                                <xsl:matching-substring>
                                    <xsl:value-of select="."/>
                                </xsl:matching-substring>
                            </xsl:analyze-string>
                        </xsl:variable>
                        <!-- gets the names of the columns used for @when, @notBefore, and @notAfter machine-readable dates and puts them into attributes. 
                                Note that the column-mapping creates only one element per category of date (e.g., "birth", "death", "floruit"), not one for each of the 
                                associated machine-readable columns (e.g., "birth notBefore"). -->
                        <!-- ??? The following regex will run into problems if there are more than 10 sources with the same prefix! (E.g., 'Source_1' will also match 'Source_11') -->
                        <!-- ??? This could be made more efficient with variables -->
                        <xsl:if
                            test="/root/row[1]/*[matches(name(), concat($date-type, '_when', '\.', $date-source))]">
                            <xsl:attribute name="whenColumn"
                                select="name(/root/row[1]/*[matches(name(), concat($date-type, '_when', '\.', $date-source))])"
                            />
                        </xsl:if>
                        <xsl:if
                            test="/root/row[1]/*[matches(name(), concat($date-type, '_notBefore', '\.', $date-source))]">
                            <xsl:attribute name="notBeforeColumn"
                                select="name(/root/row[1]/*[matches(name(), concat($date-type, '_notBefore', '\.', $date-source))])"
                            />
                        </xsl:if>
                        <xsl:if
                            test="/root/row[1]/*[matches(name(), concat($date-type, '_notAfter', '\.', $date-source))]">
                            <xsl:attribute name="notAfterColumn"
                                select="name(/root/row[1]/*[matches(name(), concat($date-type, '_notAfter', '\.', $date-source))])"
                            />
                        </xsl:if>
                    </xsl:if>

                    <!-- processes author/editor elements -->
                    <xsl:if test="matches(name(), '^author_ref|^editor_ref')">
                        <xsl:variable name="author-type">
                            <!-- captures the type of element -->
                            <xsl:choose>
                                <xsl:when test="matches(name(), '^author[\._]')">author</xsl:when>
                            </xsl:choose>
                            <xsl:choose>
                                <xsl:when test="matches(name(), '^editor[\._]')">editor</xsl:when>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="author-source">
                            <!-- captures the name of the source column this column is using, to use when constructing the machine-readable date attribute columns below -->
                            <xsl:analyze-string select="name()" regex="Source_[0-9]+">
                                <xsl:matching-substring>
                                    <xsl:value-of select="."/>
                                </xsl:matching-substring>
                            </xsl:analyze-string>
                        </xsl:variable>
                        <!-- gets the names of the columns used for @ref and @role and puts them into attributes. 
                                Note that the column-mapping creates only one element per category of author (e.g., "birth", "death", "floruit"), not one for each of the 
                                associated machine-readable columns (e.g., "birth notBefore"). -->
                        <!-- ??? The following regex will run into problems if there are more than 10 sources with the same prefix! (E.g., 'Source_1' will also match 'Source_11') -->
                        <!-- ??? This could be made more efficient with variables -->
                        <!-- ??? This might have problems if there are multiple columns with the same type and source -->


                        <xsl:variable name="refColumn" select="name()"/>
                        <xsl:attribute name="refColumn" select="$refColumn"/>

                        <xsl:if
                            test="/root/row[1]/*[matches(name(), concat($author-type, '_role', '(\.', $author-source, ')?'))]">
                            <xsl:attribute name="roleColumn"
                                select="name(/root/row[1]/*[matches(name(), concat($author-type, '_role', '(\.', $author-source, ')?'))])"
                            />
                        </xsl:if>

                    </xsl:if>

                    <!-- adds relation name, using as a value the text in the column name immediately after the element name ("relation_"). 
                    Triple hyphens are turned into colons (:) to allow prefixed namespaces. -->
                    <xsl:if test="matches(name(), '^relation_[a-zA-Z\-]+')">
                        <xsl:attribute name="ref"
                            select="replace(replace(replace(name(), 'relation_', ''), '\..*$', ''), '\-\-\-', ':')"
                        />
                    </xsl:if>

                    <xsl:attribute name="column" select="name()"/>
                    <!-- adds syriaca-headword -->
                    <xsl:choose>
                        <xsl:when test="matches(name(), '^[a-zA-Z]*_syriaca-headword')">
                            <xsl:attribute name="syriaca-tags" select="'#syriaca-headword'"/>
                        </xsl:when>
                    </xsl:choose>

                    <!-- adds sourceUriColumn -->
                    <!-- ??? This could be consolidated with the $date-source variable above. -->

                    <!-- splits the column name into parts at the dots. Removes language codes and witness columns for ease of processing. -->
                    <xsl:variable name="tokenized-column-name"
                        select="tokenize(replace(replace(name(), $lang-regex, ''), '^(witnesses|cites)\.[^\.]+', '$1'), '\.')"/>

                    <!-- grabs the part of the column name that contains the source column name -->
                    <xsl:variable name="source-name"
                        select="$tokenized-column-name[last() and matches(., '^(Source|Edition|Translation|Version|Glossary|Apparatus|PrintCatalogue|DigitalCatalogue|Ms|OriginalWithSyriacEvidence|Literature|ReferenceWork)_[0-9]+')]"/>

                    <xsl:if test="string-length($source-name)">
                        <xsl:attribute name="sourceUriColumn" select="$source-name"/>
                    </xsl:if>

                    <!-- adds an @column containing the numbered position of the column in the spreadsheet. This is used in the column-mapping template to 
                            determine which column to grab data from for this element. -->
                    <xsl:attribute name="column" select="position()"/>
                </xsl:element>
            </xsl:if>
        </xsl:for-each>

        <!-- MANUAL COLUMN MAPPING -->
        <!-- !!! Insert any manual column mapping here. Each column in the spreadsheet should have a unique name. Note that spaces in column names are converted to underscores (_). 
            For example ... -->
        <!-- ??? This might need a little debugging. Mainly, I'm not entirely sure that whether using column names instead of numbers 
            works properly. If that's a problem, you could try it with column numbers instead of names. -->
        <persName xml:lang="en" sourceUriColumn="Brooks_URI" syriaca-tags="#syriaca-headword"
            column="Name_in_Index"/>
        <note xml:lang="en" type="abstract" column="Additional_Info"/>
        <birth xml:lang="en" whenColumn="Birth_Standard" notBeforeColumn="Birth_Not_Before"
            notAfterColumn="Birth_Not_After" sourceUriColumn="Brooks_URI" column="Birth"/>
        <citedRange unit="pp" sourceUriColumn="Brooks_URI" column="99"/>
    </xsl:variable>

    <!-- DIRECTORY -->
    <!-- specifies where the output TEI files should go -->
    <!-- !!! Change this to where you want the output files to be placed relative to the XML file being converted. 
        This should end with a trailing slash (/).-->
    <xsl:variable name="directory">sample-files/works/</xsl:variable>

    <!-- CUSTOM FUNCTIONS -->
    <!-- used in auto column-mapping to determine the element name and attributes that should be created for that column. 
        Column naming format is "elementName attributeValueOrType.sourceColumnName.languageCode" -->
    <xsl:function name="syriaca:column-name">
        <xsl:param name="column-name" as="xs:string"/>
        <!-- separates the column name into its relevant parts -->
        <xsl:analyze-string select="$column-name"
            regex="^([a-zA-Z0-9\-]+)(_([a-zA-Z0-9\-]+))?(\.((Source|Edition|Translation|Version|Glossary|Apparatus|PrintCatalogue|DigitalCatalogue|Ms|OriginalWithSyriacEvidence|Literature|ReferenceWork)_[0-9]+))?(\.([a-zA-Z0-9\-]+))?$">
            <xsl:matching-substring>
                <elementName>
                    <xsl:value-of select="regex-group(1)"/>
                </elementName>
                <attributeValueOrType>
                    <xsl:value-of select="regex-group(3)"/>
                </attributeValueOrType>
                <sourceColumnName>
                    <xsl:value-of select="regex-group(5)"/>
                </sourceColumnName>
                <languageCode>
                    <xsl:value-of select="regex-group(7)"/>
                </languageCode>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>

    <!-- date processing by Winona Salesky -->
    <!-- creates the dates to be used for @syriaca-computed-start and @syriaca-computed-end. 
        Called by the column-mapping template -->
    <xsl:function name="syriaca:custom-dates" as="xs:date">
        <xsl:param name="date" as="xs:string"/>
        <xsl:variable name="trim-date" select="normalize-space($date)"/>
        <xsl:choose>
            <xsl:when test="starts-with($trim-date, '0000') and string-length($trim-date) eq 4">
                <xsl:text>0001-01-01</xsl:text>
            </xsl:when>
            <xsl:when test="string-length($trim-date) eq 4">
                <xsl:value-of select="concat($trim-date, '-01-01')"/>
            </xsl:when>
            <xsl:when test="string-length($trim-date) eq 5">
                <xsl:value-of select="concat($trim-date, '-01-01')"/>
            </xsl:when>
            <xsl:when test="string-length($trim-date) eq 5">
                <xsl:value-of select="concat($trim-date, '-01-01')"/>
            </xsl:when>
            <xsl:when test="string-length($trim-date) eq 7">
                <xsl:value-of select="concat($trim-date, '-01')"/>
            </xsl:when>
            <xsl:when test="string-length($trim-date) eq 3">
                <xsl:value-of select="concat('0', $trim-date, '-01-01')"/>
            </xsl:when>
            <xsl:when test="string-length($trim-date) eq 2">
                <xsl:value-of select="concat('00', $trim-date, '-01-01')"/>
            </xsl:when>
            <xsl:when test="string-length($trim-date) eq 1">
                <xsl:value-of select="concat('000', $trim-date, '-01-01')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$trim-date"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Applies the TEI namespace to all descendants of a node. -->
    <xsl:function name="syriaca:include-tei-children" as="node()*">
        <xsl:param name="parent-node" as="node()*"/>
        <xsl:choose>
            <xsl:when test="$parent-node/*">
                <xsl:for-each select="$parent-node/node()">
                    <xsl:choose>
                        <xsl:when test="local-name()">
                            <xsl:element name="{local-name()}"
                                namespace="http://www.tei-c.org/ns/1.0">
                                <xsl:copy-of select="attribute::* | syriaca:include-tei-children(.)"
                                />
                            </xsl:element>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="normalize-space($parent-node)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="functx:substring-after-if-contains" as="xs:string?"
        xmlns:functx="http://www.functx.com">
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:param name="delim" as="xs:string"/>

        <xsl:sequence
            select="
                if (contains($arg, $delim))
                then
                    substring-after($arg, $delim)
                else
                    $arg
                "/>

    </xsl:function>


    <xsl:function name="functx:name-test" as="xs:boolean" xmlns:functx="http://www.functx.com">
        <xsl:param name="testname" as="xs:string?"/>
        <xsl:param name="names" as="xs:string*"/>

        <xsl:sequence
            select="
                $testname = $names
                or
                $names = '*'
                or
                functx:substring-after-if-contains($testname, ':') =
                (for $name in $names
                return
                    substring-after($name, '*:'))
                or
                substring-before($testname, ':') =
                (for $name in $names[contains(., ':*')]
                return
                    substring-before($name, ':*'))
                "/>

    </xsl:function>

    <xsl:function name="functx:remove-attributes" as="element()"
        xmlns:functx="http://www.functx.com">
        <xsl:param name="elements" as="element()*"/>
        <xsl:param name="names" as="xs:string*"/>

        <xsl:for-each select="$elements">
            <xsl:element name="{node-name(.)}">
                <xsl:sequence
                    select="
                        (@*[not(functx:name-test(name(), $names))],
                        node())"
                />
            </xsl:element>
        </xsl:for-each>

    </xsl:function>

    <xsl:function name="syriaca:remove-attributes" as="node()*">
        <xsl:param name="nodes" as="node()*"/>
        <xsl:param name="names" as="xs:string*"/>
        <xsl:for-each select="$nodes">
            <xsl:copy-of select="functx:remove-attributes(., $names)"/>
        </xsl:for-each>
    </xsl:function>

    <xsl:function name="functx:is-node-in-sequence-deep-equal" as="xs:boolean"
        xmlns:functx="http://www.functx.com">
        <xsl:param name="node" as="node()?"/>
        <xsl:param name="seq" as="node()*"/>

        <xsl:sequence
            select="
                some $nodeInSeq in $seq
                    satisfies deep-equal($nodeInSeq, $node)
                "/>

    </xsl:function>

    <xsl:function name="functx:distinct-deep" as="node()*" xmlns:functx="http://www.functx.com">
        <xsl:param name="nodes" as="node()*"/>

        <xsl:sequence
            select="
                for $seq in (1 to count($nodes))
                return
                    $nodes[$seq][not(functx:is-node-in-sequence-deep-equal(
                    ., $nodes[position() &lt; $seq]))]
                "/>

    </xsl:function>

    <!-- Consolidates matching elements from different sources -->
    <xsl:function name="syriaca:consolidate-sources" as="node()*">
        <xsl:param name="input-nodes" as="node()*"/>
        <xsl:for-each
            select="functx:distinct-deep(syriaca:remove-attributes($input-nodes, ('source', 'syriaca-tags')))">
            <xsl:variable name="this-node" select="."/>
            <xsl:element name="{$this-node/name()}" namespace="http://www.tei-c.org/ns/1.0">
                <xsl:variable name="source"
                    select="$input-nodes[deep-equal($this-node, functx:remove-attributes(., ('source', 'syriaca-tags')))]/attribute::source"/>
                <xsl:variable name="syriaca-tags"
                    select="$input-nodes[deep-equal($this-node, functx:remove-attributes(., ('source', 'syriaca-tags')))]/attribute::syriaca-tags"/>
                <xsl:for-each select="$this-node/@*">
                    <xsl:attribute name="{name()}" select="."/>
                </xsl:for-each>
                <xsl:if test="$syriaca-tags != ''">
                    <xsl:attribute name="syriaca-tags" select="$syriaca-tags"/>
                </xsl:if>
                <xsl:if test="$source != ''">
                    <xsl:attribute name="source" select="$source"/>
                </xsl:if>
                <xsl:copy-of select="$this-node/node()"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:function>

    <!-- Adds xml:id to each node -->
    <xsl:function name="syriaca:add-xml-id" as="node()*">
        <xsl:param name="input-nodes" as="node()*"/>
        <xsl:param name="record-id" as="xs:string"/>
        <xsl:param name="id-prefix" as="xs:string"/>
        <xsl:for-each select="$input-nodes">
            <xsl:variable name="index" select="index-of($input-nodes, .)"/>
            <xsl:element name="{name()}" namespace="http://www.tei-c.org/ns/1.0">
                <xsl:attribute name="xml:id" select="concat($id-prefix, $record-id, '-', $index[1])"/>
                <xsl:copy-of select="@*"/>
                <!--<xsl:for-each select="@*">
                    <xsl:attribute name="{name()}" select="."/>
                </xsl:for-each>-->
                <xsl:copy-of select="node()"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:function>

    <!-- MAIN TEMPLATE -->
    <!-- processes each row of the spreadsheet -->
    <xsl:template match="/root">
        <!-- creates ids for new works. -->
        <!-- ??? How should we deal with matched works, where the existing TEI records need to be supplemented? -->
        <xsl:for-each select="row[not(contains(., '***'))]">
            <xsl:variable name="record-id">
                <!-- gets a record ID from the New_URI column, or generates one if that column is blank -->
                <xsl:choose>
                    <xsl:when test="New_URI != ''">
                        <xsl:value-of select="New_URI"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat('unresolved-', generate-id())"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <!-- creates the URI from the record ID -->
            <xsl:variable name="record-uri" select="concat('http://syriaca.org/work/', New_URI)"/>

            <!-- creates bibls for this record (row) using the @sourceUriColumn attributes defined in $column-mapping -->
            <xsl:variable name="record-bibls">
                <xsl:call-template name="bibls">
                    <xsl:with-param name="record-id" select="$record-id"/>
                    <xsl:with-param name="this-row" select="*"/>
                </xsl:call-template>
            </xsl:variable>

            <!-- converts spreadsheet row contents into TEI elements for this record using the $column-mapping variable -->
            <xsl:variable name="converted-columns">
                <xsl:call-template name="column-mapping">
                    <xsl:with-param name="columns-to-convert" select="*"/>
                    <xsl:with-param name="record-bibls" select="$record-bibls"/>
                    <xsl:with-param name="record-uri" select="$record-uri"/>
                </xsl:call-template>
            </xsl:variable>

            <!-- creates a variable containing the path of the file to be created for this record, in the location defined by $directory -->
            <xsl:variable name="filename">
                <xsl:choose>
                    <!-- tests whether there is sufficient data to create a complete record. If not, puts it in an 'incomplete' folder inside the $directory -->
                    <xsl:when
                        test="empty($converted-columns/*[@syriaca-tags = '#syriaca-headword'])">
                        <xsl:value-of
                            select="concat($directory, '/incomplete/', $record-id, '.xml')"/>
                    </xsl:when>
                    <!-- if record is complete and has a URI, puts it in the $directory folder -->
                    <xsl:when test="New_URI != ''">
                        <xsl:value-of select="concat($directory, $record-id, '.xml')"/>
                    </xsl:when>
                    <!-- if record doesn't have a URI, puts it in 'unresolved' folder inside the $directory  -->
                    <xsl:otherwise>
                        <xsl:value-of select="concat($directory, 'unresolved/', $record-id, '.xml')"
                        />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <!-- creates the XML file, if the filename has been sucessfully created. -->
            <xsl:if test="$filename != ''">
                <xsl:result-document href="{$filename}" format="xml">
                    <!-- adds the xml-model instruction with the link to the Syriaca.org validator -->
                    <xsl:processing-instruction name="xml-model">
                    <xsl:text>href="http://syriaca.org/documentation/syriaca-tei-main.rnc" type="application/relax-ng-compact-syntax"</xsl:text>
                </xsl:processing-instruction>
                    <xsl:value-of select="$n"/>

                    <!-- RECORD CONTENT BEGINS -->
                    <TEI xml:lang="en" xmlns="http://www.tei-c.org/ns/1.0">
                        <xsl:variable name="en-headword"
                            select="$converted-columns/*[@syriaca-tags = '#syriaca-headword' and starts-with(@xml:lang, 'en')]"/>
                        <!-- Adds header from the header template -->
                        <xsl:call-template name="header">
                            <xsl:with-param name="record-id" select="$record-id"/>
                            <xsl:with-param name="converted-columns" select="$converted-columns"/>
                            <xsl:with-param name="en-headword" select="$en-headword"/>
                        </xsl:call-template>
                        <text>
                            <body>
                                <bibl>
                                    <!-- creates an @xml:id and adds it to the bibl element -->
                                    <xsl:attribute name="xml:id"
                                        select="concat('work-', $record-id)"/>
                                    <xsl:attribute name="type" select="'lawd:ConceptualWork'"/>
                                    <!-- adds the bibl subject and genre tags -->
                                    <xsl:if test="bibl_ana != ''">
                                        <xsl:attribute name="ana" select="bibl_ana"/>
                                    </xsl:if>

                                    <!-- allows referencing the current row within nested for-each statements -->
                                    <xsl:variable name="this-row" select="."/>

                                    <!-- BIBL ELEMENTS -->
                                    <!-- these copy-of instructions grab specific TEI elements from the $converted-columns variable (columns processed from spreadsheet) 
                                and import them here. -->
                                    <!-- !!! If you have added any new types of elements in $column-mapping, you must call them here. 
                                You must include @xpath-default-namespace="http://www.tei-c.org/ns/1.0" 
                                You can also change the order of these elements according to your preference, so long as it still produces valid TEI. -->
                                    <xsl:copy-of
                                        select="syriaca:add-xml-id(syriaca:consolidate-sources($converted-columns/title), $record-id, 'name')"
                                        xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>
                                    <xsl:copy-of select="$converted-columns/author"
                                        xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>
                                    <xsl:copy-of select="$converted-columns/editor"
                                        xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>

                                    <!-- IDNO -->
                                    <!-- gives the work URI as an idno -->
                                    <xsl:if test="New_URI != ''">
                                        <idno type="URI">
                                            <xsl:value-of select="$record-uri"/>
                                        </idno>
                                    </xsl:if>
                                    <xsl:copy-of select="$converted-columns/idno"
                                        xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>

                                    <textLang mainLang="syr"/>

                                    <xsl:copy-of
                                        select="syriaca:consolidate-sources($converted-columns/date)"
                                        xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>
                                    <xsl:copy-of
                                        select="syriaca:consolidate-sources($converted-columns/extent)"
                                        xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>

                                    <xsl:if
                                        test="$converted-columns/tei:note[@type = 'abstract'] != ''">
                                        <xsl:element name="note"
                                            namespace="http://www.tei-c.org/ns/1.0">
                                            <!-- this can't use the syriaca:add-xml-id function because the attribute value has a different format -->
                                            <xsl:attribute name="xml:id"
                                                select="concat('abstract-en-', $record-id)"/>
                                            <xsl:copy-of
                                                select="$converted-columns/note[@type = 'abstract']/(node() | @*)"
                                                xpath-default-namespace="http://www.tei-c.org/ns/1.0"
                                            > </xsl:copy-of>
                                        </xsl:element>
                                    </xsl:if>
                                    <xsl:copy-of
                                        select="$converted-columns/note[@type != 'abstract']"
                                        xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>

                                    <!-- BIBLS -->
                                    <!-- inserts bibl elements created by the bibls template-->
                                    <xsl:copy-of select="$record-bibls/bibl"
                                        xpath-default-namespace="http://www.tei-c.org/ns/1.0"
                                        copy-namespaces="no"/>

                                    <!-- RELATIONS -->
                                    <!-- imports relation elements from $converted-columns-->
                                    <xsl:variable name="relations"
                                        select="$converted-columns/relation"
                                        xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>
                                    <xsl:if test="$relations">
                                        <listRelation>
                                            <xsl:copy-of
                                                select="syriaca:consolidate-sources($converted-columns/relation)"
                                                xpath-default-namespace="http://www.tei-c.org/ns/1.0"
                                            />
                                        </listRelation>
                                    </xsl:if>

                                </bibl>
                            </body>
                        </text>
                    </TEI>
                </xsl:result-document>

            </xsl:if>

        </xsl:for-each>

    </xsl:template>

    <!-- TEI HEADER TEMPLATE -->
    <!-- ??? Update the following! -->
    <!-- !!! This will need to be updated for each new spreadsheet that has different contributors -->
    <xsl:template name="header" xmlns="http://www.tei-c.org/ns/1.0">
        <xsl:param name="record-id"/>
        <xsl:param name="converted-columns"/>
        <xsl:param name="en-headword"/>
        <xsl:variable name="en-title">
            <!-- checks whether there is an English Syriaca headword. If not, just uses the record-id as the page title. -->
            <xsl:choose>
                <xsl:when test="$en-headword">
                    <xsl:value-of select="$en-headword"/>
                </xsl:when>
                <xsl:otherwise>Work <xsl:value-of select="$record-id"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="anonymous-description">
            <!-- grabs the anonymous description, if there is one. -->
            <xsl:choose>
                <xsl:when test="$converted-columns/*[@syriaca-tags = '#anonymous-description']">
                    <xsl:value-of
                        select="$converted-columns/*[@syriaca-tags = '#anonymous-description']"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="syriac-headword">
            <!-- grabs the Syriac headword, if there is one. -->
            <xsl:choose>
                <xsl:when
                    test="$converted-columns/*[@syriaca-tags = '#syriaca-headword' and starts-with(@xml:lang, 'syr')]">
                    <xsl:value-of
                        select="$converted-columns/*[@syriaca-tags = '#syriaca-headword' and starts-with(@xml:lang, 'syr')]"
                    />
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <!-- combines the English and Syriac headwords to make the record title -->
        <xsl:variable name="record-title">
            <xsl:value-of select="$en-title"/>
            <xsl:choose>
                <xsl:when test="string-length($anonymous-description)"> — <xsl:value-of
                        select="$anonymous-description"/></xsl:when>
                <xsl:when test="string-length($syriac-headword)"> — <foreign xml:lang="syr"
                            ><xsl:value-of select="$syriac-headword"/></foreign></xsl:when>
            </xsl:choose>
        </xsl:variable>
        <teiHeader>
            <fileDesc>
                <titleStmt>
                    <title level="a" xml:lang="en">
                        <xsl:copy-of select="$record-title"/>
                    </title>
                    <sponsor>Syriaca.org: The Syriac Reference Portal</sponsor>
                    <funder>The International Balzan Prize Foundation</funder>
                    <funder>The National Endowment for the Humanities</funder>
                    <principal>David A. Michelson</principal>

                    <!-- EDITORS -->
                    <editor role="general"
                        ref="http://syriaca.org/documentation/editors.xml#dschwartz">Daniel L. Schwartz</editor>

                    <!-- CREATOR -->
                    <!-- designates the editor responsible for creating this work record (may be different from the file creator) -->
                    <editor role="creator"
                        ref="http://syriaca.org/documentation/editors.xml#dschwartz">Daniel L. Schwartz</editor>

                    <!-- CONTRIBUTORS -->
                    <respStmt>
                        <resp>Editing and data entry by</resp>
                        <name type="person"
                            ref="http://syriaca.org/documentation/editors.xml#dschwartz">Daniel L. Schwartz</name>
                    </respStmt>
                    <respStmt>
                        <resp>Editing, proofreading, data architecture, and encoding by</resp>
                        <name type="person"
                            ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P.
                            Gibson</name>
                    </respStmt>
                    <respStmt>
                        <resp>Data architecture by</resp>
                        <name type="person"
                            ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A.
                            Michelson</name>
                    </respStmt>
                </titleStmt>
                <editionStmt>
                    <edition n="1.0"/>
                </editionStmt>
                <publicationStmt>
                    <authority>Syriaca.org: The Syriac Reference Portal</authority>
                    <idno type="URI">http://syriaca.org/work/<xsl:value-of select="$record-id"
                        />/tei</idno>
                    <xsl:element name="availability">
                        <licence target="http://creativecommons.org/licenses/by/3.0/">
                            <p>Distributed under a Creative Commons Attribution 3.0 Unported
                                License.</p>
                            <!-- !!! If copyright material is included, the following should be adapted and used. -->
                            <!--<p>This entry incorporates copyrighted material from the following work(s):
                                    <listBibl>
                                            <bibl>
                                                <ptr>
                                                    <xsl:attribute name="target" select="'foo1'"/>
                                                </ptr>
                                            </bibl>
                                            <bibl>
                                                <ptr>
                                                    <xsl:attribute name="target" select="'foo2'"/>
                                                </ptr>
                                            </bibl>
                                    </listBibl>
                                    <note>used under a Creative Commons Attribution license <ref target="http://creativecommons.org/licenses/by/3.0/"/></note>
                                </p>-->
                        </licence>
                    </xsl:element>
                    <date>
                        <xsl:value-of select="current-date()"/>
                    </date>
                </publicationStmt>

                <!-- SERIES STATEMENTS -->
                <seriesStmt>
                    <title level="s">New Handbook of Syriac Literature</title>
                    <editor role="general"
                        ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P.
                        Gibson</editor>
                    <editor role="general"
                        ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A.
                        Michelson</editor>
                    <respStmt>
                        <resp>Edited by</resp>
                        <name type="person"
                            ref="http://syriaca.org/documentation/editors.xml#ngibson">Nathan P.
                            Gibson</name>
                    </respStmt>
                    <respStmt>
                        <resp>Edited by</resp>
                        <name type="person"
                            ref="http://syriaca.org/documentation/editors.xml#dmichelson">David A.
                            Michelson</name>
                    </respStmt>
                    <idno type="URI">http://syriaca.org/nhsl</idno>
                    <!-- One or more volumes containing this record can go here. -->
                    <!--<biblScope unit="vol" from="2" to="2">
                        <title level="m">Syriac Scientific and Philosophical Literature</title>
                        <idno type="URI">http://syriaca.org/sci-phil</idno>
                    </biblScope>-->
                </seriesStmt>
                <sourceDesc>
                    <p>Born digital.</p>
                </sourceDesc>
            </fileDesc>

            <!-- SYRIACA.ORG TEI DOCUMENTATION -->
            <encodingDesc>
                <editorialDecl>
                    <p>This record created following the Syriaca.org guidelines. Documentation
                        available at: <ref target="http://syriaca.org/documentation"
                            >http://syriaca.org/documentation</ref>.</p>
                    <interpretation>
                        <p>Approximate dates described in terms of centuries or partial centuries
                            have been interpreted as documented in <ref
                                target="http://syriaca.org/documentation/dates.html">Syriaca.org
                                Dates</ref>.</p>
                    </interpretation>
                </editorialDecl>
                <classDecl>
                    <taxonomy>
                        <category xml:id="syriaca-headword">
                            <catDesc>The name used by Syriaca.org for document titles, citation, and
                                disambiguation. These names have been created according to the
                                Syriac.org guidelines for headwords: <ref
                                    target="http://syriaca.org/documentation/headwords.html"
                                    >http://syriaca.org/documentation/headwords.html</ref>.</catDesc>
                        </category>
                        <category xml:id="syriaca-anglicized">
                            <catDesc>An anglicized version of a name, included to facilitate
                                searching.</catDesc>
                        </category>
                    </taxonomy>
                </classDecl>
            </encodingDesc>
            <profileDesc>
                <langUsage>
                    <!-- !!! Additional languages, if used, should be added here. -->
                    <language ident="syr">Unvocalized Syriac of any variety or period</language>
                    <language ident="syr-Syrj">Vocalized West Syriac</language>
                    <language ident="syr-Syrn">Vocalized East Syriac</language>
                    <language ident="en">English</language>
                    <language ident="en-x-gedsh">Names or terms Romanized into English according to
                        the standards adopted by the Gorgias Encyclopedic Dictionary of the Syriac
                        Heritage</language>
                    <language ident="ar">Arabic</language>
                    <language ident="fr">French</language>
                    <language ident="de">German</language>
                    <language ident="la">Latin</language>
                </langUsage>
            </profileDesc>
            <revisionDesc status="draft">

                <!-- FILE CREATOR -->
                <change who="http://syriaca.org/documentation/editors.xml#ngibson" n="1.0">
                    <xsl:attribute name="when" select="current-date()"/>CREATED: work</change>

                <!-- PLANNED CHANGES -->
                <!-- ??? Are there any change @type='planned' ? -->
            </revisionDesc>
        </teiHeader>
    </xsl:template>

    <!-- COLUMN MAPPING TEMPLATE -->
    <!-- converts spreadsheet columns using $column-mapping variable above -->
    <!-- ??? This template does not yet try to reconcile identical elements coming from different sources -->
    <!-- ??? This might be producing extra spaces on some Syriac names -->
    <xsl:template name="column-mapping" xmlns="http://www.tei-c.org/ns/1.0">
        <!-- the columns of this particular row that should be converted, with the data they contain. -->
        <xsl:param name="columns-to-convert"/>
        <xsl:param name="record-bibls"/>
        <xsl:param name="record-uri"/>
        <!-- attributes that should not be attached to converted columns -->
        <xsl:variable name="custom-attributes"
            select="('column', 'sourceUriColumn', 'whenColumn', 'notBeforeColumn', 'notAfterColumn', 'refColumn', 'roleColumn')"/>
        <!-- cycles through each of the columns that should be converted, to pull them into the elements pre-defined in $column-mapping -->
        <xsl:for-each select="$columns-to-convert">
            <xsl:variable name="column-name" select="name()"/>
            <xsl:variable name="column-position" select="position()"/>
            <xsl:if test=". != ''">
                <!-- grabs the contents of the column so that it can be used in nested for-each statements -->
                <xsl:variable name="column-contents">
                    <xsl:copy-of select="syriaca:include-tei-children(.)"/>
                </xsl:variable>
                <!-- cycles through each of the elements pre-defined in $column-mapping, checking whether they have the current spreadsheet column as @column 
                    and processing the data if they do. -->
                <xsl:for-each select="$column-mapping/*">
                    <xsl:variable name="this-column" select="."/>
                    <!-- gets the bibl URI number from the cell that contains the source for the spreadsheet cell being processed -->
                    <xsl:variable name="this-column-source"
                        select="$columns-to-convert[name() = $this-column/@sourceUriColumn][1]"/>
                    <!-- turns that bibl URI number into a complete Syriaca.org URI -->
                    <xsl:variable name="column-uri"
                        select="concat('http://syriaca.org/bibl/', $this-column-source)"/>
                    <!-- gets the name/position of the spreadsheet column that contains the citedRange data for this cell (using the source column name) -->
                    <xsl:variable name="cited-range"
                        select="$column-mapping/citedRange[@sourceUriColumn = name($this-column-source)]/@column"/>
                    <!-- gets the contents of that citedRange cell (e.g., page number) -->
                    <xsl:variable name="cited-range-contents"
                        select="$columns-to-convert[position() = $cited-range or name() = $cited-range]"/>
                    <!-- gets the name/position of the spreadsheet column that contains notes to be added to the bibl for this cell (using the source column name) -->
                    <xsl:variable name="bibl-note"
                        select="$column-mapping/bibl-note[@sourceUriColumn = name($this-column-source)]/@column"/>
                    <!-- gets the contents of that bibl-note cell (e.g., page number) -->
                    <xsl:variable name="bibl-note-contents"
                        select="$columns-to-convert[position() = $bibl-note or name() = $bibl-note]"/>
                    <!-- gets the values of subsidiary date columns (machine-readable dates) to use as attribute values  -->
                    <xsl:variable name="when"
                        select="$columns-to-convert[name() = $this-column/@whenColumn]"/>
                    <xsl:variable name="not-before"
                        select="$columns-to-convert[name() = $this-column/@notBeforeColumn]"/>
                    <xsl:variable name="not-after"
                        select="$columns-to-convert[name() = $this-column/@notAfterColumn]"/>
                    <xsl:variable name="author-ref"
                        select="$columns-to-convert[name() = $this-column/@refColumn]"/>
                    <xsl:variable name="author-role"
                        select="$columns-to-convert[name() = $this-column/@roleColumn]"/>
                    <!-- checks whether this $column-mapping/@column matches the name or position of the spreadsheet column being processed. 
                        (Column name is used for manual column mapping; unique column names required. Column position is used for auto column mapping.) -->
                    <xsl:if
                        test="string(@column) = string($column-name) or string(@column) = string($column-position)">
                        <!-- creates an element with the same name as the $column-mapping element, 
                        unless it is an event attestation, which needs to create multiple elements -->
                        <xsl:choose>
                            <xsl:when test="name() = 'event' and @type = 'attestation'">
                                <!-- Creates an event type="attestation" for each work URI -->
                                <xsl:variable name="node-name" select="name()"/>
                                <xsl:variable name="node-attributes"
                                    select="attribute::*[not(name() = $custom-attributes) and not(. != '')]"/>
                                <xsl:variable name="attestation-URIs"
                                    select="tokenize($column-contents, '\s*,\s*')"/>
                                <xsl:variable name="en-headword"
                                    select="normalize-space($columns-to-convert[matches(name(.), '.*syriaca\-headword.*\.en.*') and . != ''][1])"/>
                                <xsl:for-each select="$attestation-URIs">
                                    <!-- can replace this with localhost if there is error on dev server. Must have local exist running. -->
                                    <!--<xsl:variable name="attesting-work-url" select="concat(replace(.,'http://syriaca.org','http://wwwb.library.vanderbilt.edu'),'/tei')"/>-->
                                    <xsl:variable name="attesting-work-url"
                                        select="concat(replace(., 'http://syriaca.org/work/', 'http://localhost:8080/exist/apps/srophe/work/'), '/tei')"/>
                                    <xsl:variable name="attesting-work-title">
                                        <xsl:copy-of
                                            select="document($attesting-work-url)/TEI/text/body/bibl/title[contains(@syriaca-tags, '#syriaca-headword') and starts-with(@xml:lang, 'en')]"
                                            xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>
                                    </xsl:variable>
                                    <xsl:element name="{$node-name}">
                                        <xsl:copy-of select="$node-attributes"/>
                                        <p xml:lang="en"><xsl:value-of select="$en-headword"/> is
                                            commemorated in <title ref="{.}"><xsl:value-of
                                                  select="$attesting-work-title"/></title>.</p>
                                    </xsl:element>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:element name="{name()}">
                                    <!-- adds the general attributes defined in $column-mapping, plus date attributes-->
                                    <!-- !!! If you add new types of attributes in $column-mapping, you must also create them here -->
                                    <xsl:copy-of select="@*[not(name() = $custom-attributes)]"/>
                                    <xsl:if test="$when != ''">
                                        <xsl:attribute name="when" select="$when"/>
                                        <xsl:attribute name="syriaca-computed-start"
                                            select="syriaca:custom-dates($when)"/>
                                    </xsl:if>
                                    <xsl:if test="$not-before != ''">
                                        <xsl:attribute name="notBefore" select="$not-before"/>
                                        <xsl:attribute name="syriaca-computed-start"
                                            select="syriaca:custom-dates($not-before)"/>
                                    </xsl:if>
                                    <xsl:if test="$not-after != ''">
                                        <xsl:attribute name="notAfter" select="$not-after"/>
                                        <xsl:attribute name="syriaca-computed-end"
                                            select="syriaca:custom-dates($not-after)"/>
                                    </xsl:if>
                                    <xsl:if test="$author-ref != ''">
                                        <xsl:attribute name="ref" select="$author-ref"/>
                                    </xsl:if>
                                    <xsl:if test="$author-role != ''">
                                        <xsl:attribute name="role" select="$author-role"/>
                                    </xsl:if>
                                    <!-- adds the source column by matching the @sourceUriColumn (and corresponding citedRange, where present) to the available bibl ptr elements.  -->
                                    <xsl:choose>
                                        <xsl:when
                                            test="@sourceUriColumn != '' and $cited-range-contents != '' and tei:citedRange != ''">
                                            <xsl:attribute name="source"
                                                select="concat('#', $record-bibls/*[tei:ptr/@target = $column-uri and matches($cited-range-contents, tei:citedRange/text())][1]/@xml:id)"
                                            />
                                        </xsl:when>
                                        <xsl:when test="@sourceUriColumn != ''">
                                            <xsl:attribute name="source"
                                                select="concat('#', $record-bibls/*[tei:ptr/@target = $column-uri][1]/@xml:id)"
                                            />
                                        </xsl:when>
                                    </xsl:choose>
                                    <!-- creates element contents. Default is to put the contents of the column directly inside the element, but certain elements 
                                        have to be handled differently. -->
                                    <!-- !!! If you have added element types in $column-mapping that require special handling (e.g., as an attribute value or inside a <desc>), 
                                        you should process them here. -->
                                    <xsl:choose>
                                        <!-- puts column contents inside a <label> -->
                                        <xsl:when test="name() = 'state'">
                                            <xsl:element name="label">
                                                <xsl:value-of select="$column-contents"/>
                                            </xsl:element>
                                        </xsl:when>
                                        <!-- puts column contents inside a <label> -->
                                        <xsl:when test="name() = 'trait'">
                                            <xsl:element name="label">
                                                <xsl:value-of select="$column-contents"/>
                                            </xsl:element>
                                        </xsl:when>
                                        <!-- processes relation elements -->
                                        <xsl:when test="name() = 'relation'">
                                            <!-- processes multiple comma-separated relation uris -->
                                            <!-- ??? Need to sanitize possible spaces between uris using normalize-space()? -->
                                            <xsl:variable name="tokenized-relation-uris">
                                                <xsl:for-each
                                                  select="tokenize($column-contents, ',')">
                                                  <!-- makes a partial URI into a full URI -->
                                                  <xsl:if test="not(contains(., 'http'))"
                                                  >http://syriaca.org/work/</xsl:if>
                                                  <xsl:value-of select="concat(., ' ')"/>
                                                </xsl:for-each>
                                            </xsl:variable>
                                            <xsl:choose>
                                                <!-- adds possibly identical relation -->
                                                <!-- !!! You can define more relation types here (and in $column-mapping) -->
                                                <xsl:when test="@ref = 'syriaca:possiblyIdentical'">
                                                  <xsl:attribute name="mutual"
                                                  select="concat($record-uri, ' ', normalize-space($tokenized-relation-uris))"/>
                                                  <desc xml:lang="en">This work is possibly
                                                  identical with one or more works represented in
                                                  another record</desc>
                                                </xsl:when>
                                                <xsl:when test="@ref = 'syriaca:differentFrom'">
                                                  <xsl:attribute name="mutual"
                                                  select="concat($record-uri, ' ', normalize-space($tokenized-relation-uris))"/>
                                                  <desc xml:lang="en">The following works are not
                                                  identical but have been or could be confused:
                                                  <xsl:value-of
                                                  select="string-join(($record-uri, string-join(normalize-space($tokenized-relation-uris), ', ')), ', ')"
                                                  /></desc>
                                                </xsl:when>
                                                <xsl:when test="@ref = 'syriaca:hasRelationToPlace'">
                                                  <xsl:attribute name="active" select="$record-uri"/>
                                                  <xsl:attribute name="passive"
                                                  select="normalize-space($tokenized-relation-uris)"/>
                                                  <desc xml:lang="en">This work has an unspecified
                                                  connection to places.</desc>
                                                </xsl:when>
                                                <xsl:when test="@ref = 'dcterms:isPartOf'">
                                                    <xsl:attribute name="active" select="$record-uri"/>
                                                    <xsl:attribute name="passive"
                                                        select="replace(normalize-space(string-join($tokenized-relation-uris,' ')),'\[.*?\]\s*$','')"/>
                                                    <xsl:for-each select="$tokenized-relation-uris">
                                                        <xsl:variable name="part-number" select="replace(normalize-space(.),'http.*?\[(.*?)\]\s*$','$1')"/>
                                                        <desc><label type="order" subtype="part" n="{$part-number}">part <xsl:value-of select="$part-number"/></label></desc>
          <!-- If the above doesn't work correctly, try this.                                           
<xsl:variable name="containing-works" select="normalize-space($tokenized-relation-uris)"/>
                                                    <xsl:for-each select="$containing-works">
                                                        <xsl:variable name="order" select="replace(replace(.,'.*\{',''),'\}\s*','')"/>
                                                        <xsl:attribute name="active" select="$record-uri"/>
                                                        <xsl:attribute name="passive" select="replace(.,'\s*\{\d+\}\s*','')"/>                                                        
                                                        <xsl:attribute name="type" select="'part'"/>
                                                        <desc>
                                                            <label type="order" subtype="part" n="{$order}">part <xsl:value-of select="$order"/></label>
                                                        </desc>
                                                        -->
                                                    </xsl:for-each>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                  <xsl:attribute name="active" select="$record-uri"/>
                                                  <!-- ??? Something here seems to be causing a bug that garbles the passive URI if the record ID is contained in it. 
                                                    E.g., if the relation should be 
                                                        <relation ref="skos:broadMatch" active="http://syriaca.org/work/2" passive="http://syriaca.org/work/9632"/> 
                                                    it is instead 
                                                       <relation ref="skos:broadMatch" active="http://syriaca.org/work/2" passive="http://syriaca.org/work/963http://syriaca.org/work/2"/> -->
                                                  <xsl:attribute name="passive"
                                                  select="normalize-space($tokenized-relation-uris)"
                                                  />
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:when>
                                        <!-- creates <sex> and puts the column contents into the @value -->
                                        <xsl:when test="name() = 'sex'">
                                            <xsl:attribute name="value" select="$column-contents"/>
                                            <!-- puts a long-form value into the element content -->
                                            <!-- !!! Other abbreviations for <sex> could be spelled out here. -->
                                            <xsl:choose>
                                                <xsl:when test="$column-contents = 'M'"
                                                  >male</xsl:when>
                                                <xsl:when test="$column-contents = 'F'"
                                                  >female</xsl:when>
                                            </xsl:choose>
                                        </xsl:when>
                                        <xsl:when test="name() = 'author' or name() = 'editor'">
                                            <!-- uses draft version. If you want the production/published version, change the variable below. -->
                                            <xsl:variable name="author-ref-url"
                                                select="replace($author-ref, 'syriaca.org', 'localhost:8080/exist/apps/srophe/')"/>
                                            <xsl:variable name="ref-persName">
                                                <xsl:copy-of
                                                  select="document(concat($author-ref-url, '/tei'))/TEI/text/body/listPerson/person/persName[contains(@syriaca-tags, '#syriaca-headword')]"
                                                  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
                                                />
                                            </xsl:variable>
                                            <xsl:variable name="en-name"
                                                select="$ref-persName/tei:persName[starts-with(@xml:lang, 'en')][1]"/>
                                            <xsl:variable name="syr-name"
                                                select="$ref-persName/tei:persName[starts-with(@xml:lang, 'syr')][1]"/>
                                            <persName xml:lang="{$en-name/@xml:lang}">
                                                <xsl:value-of select="$en-name"/>
                                            </persName>
                                            <xsl:if test="string-length($syr-name)"> — <persName
                                                  xml:lang="{$syr-name/@xml:lang}"><xsl:value-of
                                                  select="$syr-name"/></persName></xsl:if>
                                        </xsl:when>
                                        <!-- if the column does not meet the above tests for special processing, the column contents are put directly into the element -->
                                        <xsl:otherwise>
                                            <xsl:copy-of select="$column-contents"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:element>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- BIBLS TEMPLATE -->
    <!-- creates bibl elements for the row when called, using the @sourceUriColumn values defined in $column-mapping -->
    <!-- ??? bibl-ids are not consecutive when not all sources are used. Perhaps this could be solved by only processing the @sourceUriColumn for cells that are not blank? -->
    <xsl:template name="bibls" xmlns="http://www.tei-c.org/ns/1.0">
        <xsl:param name="record-id"/>
        <!-- the contents of the spreadsheet row being processed -->
        <xsl:param name="this-row"/>
        <!-- creates a sequence of the column names of all the source columns used in the spreadsheet. -->
        <xsl:variable name="sources"
            select="distinct-values(($this-row[matches(name(), '^(Source|Edition|Translation|Version|Glossary|Apparatus|PrintCatalogue|DigitalCatalogue|Ms|OriginalWithSyriacEvidence|Literature|ReferenceWork)_[0-9]*') and . != '']/name(), $column-mapping//@sourceUriColumn[. = $this-row[. != '']/name()]))"/>
        <!-- creates a bibl for each of the source columns used in the spreadsheet. -->
        <xsl:variable name="sources-sorted">
            <xsl:for-each select="$sources">
                <xsl:sort
                    select="index-of(('Edition', 'Translation', 'Version', 'Ms', 'Source', 'Glossary', 'Apparatus', 'PrintCatalogue', 'DigitalCatalogue', 'OriginalWithSyriacEvidence', 'Literature', 'ReferenceWork'), replace(., '_[0-9]+', ''))"/>
                <xsl:copy-of select="."/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="sources-sorted-tokenized" select="tokenize($sources-sorted, ' ')"/>
        <xsl:variable name="all-source-columns"
            select="$this-row[$sources-sorted-tokenized = name()]"/>
        <xsl:for-each select="$sources-sorted-tokenized">
            <xsl:variable name="source-uri-column" select="."/>
            <xsl:variable name="has-cited-range"
                select="$this-row[position() = $column-mapping/citedRange[@sourceUriColumn = $source-uri-column]/@column] != ''"/>
            <xsl:variable name="has-bibl-note"
                select="$this-row[position() = $column-mapping/bibl-note[@sourceUriColumn = $source-uri-column]/@column] != ''"/>

            <!-- source column -->
            <xsl:variable name="source-column" select="$this-row[name() = $source-uri-column]"/>
            <!-- or, alternatively, source column if it has content in the cited range. Note this may create problem for "witnesses" columns. -->
            <!--<xsl:variable name="source-column" select="$this-row[name()=$source-uri-column and $has-cited-range]">-->
            <xsl:for-each select="$source-column">
                <xsl:variable name="this-column-position" select="position()"/>
                <xsl:if test=". != ''">
                    <xsl:variable name="this-column" select="name()"/>
                    <!-- gets the citedRange from $column-mapping column that names this column as its @sourceUriColumn -->
                    <xsl:variable name="cited-ranges"
                        select="$column-mapping/citedRange[@sourceUriColumn = $this-column]"/>
                    <!-- gets the bibl-note from $column-mapping column that names this column as its @sourceUriColumn -->
                    <xsl:variable name="bibl-notes"
                        select="$column-mapping/bibl-note[@sourceUriColumn = $this-column]"/>
                    <!-- gets the lang from $column-mapping column that names this column as its @sourceUriColumn -->
                    <xsl:variable name="langs"
                        select="$column-mapping/lang[@sourceUriColumn = $this-column]"/>
                    <!-- gets the witnesses for this source from $column-mapping column. This is a different column from the @sourceUriColumn, which would represent the 
                        optional source column name appended to the end of the witnesses column name. -->
                    <xsl:variable name="witnesses-column-start"
                        select="concat('witnesses.', $this-column)"/>
                    <xsl:variable name="witnesses-column"
                        select="$this-row[starts-with(name(), $witnesses-column-start)]"/>
                    <xsl:variable name="witnesses-column-position">
                        <xsl:if test="$this-row[starts-with(name(), $witnesses-column-start)]">
                            <xsl:value-of
                                select="index-of($this-row/name(), $this-row/name()[starts-with(., $witnesses-column-start)])"
                            />
                        </xsl:if>
                    </xsl:variable>
                    <xsl:variable name="witnesses"
                        select="$column-mapping/witnesses[@column = $witnesses-column-position]"/>
                    <!-- gets the "cites" for this source from $column-mapping column. This is a different column from the @sourceUriColumn, which would represent the 
                        optional source column name appended to the end of the "cites" column name. -->
                    <xsl:variable name="cites-column-start" select="concat('cites.', $this-column)"/>
                    <xsl:variable name="cites-column"
                        select="$this-row[starts-with(name(), $cites-column-start)]"/>
                    <xsl:variable name="cites-column-position">
                        <xsl:if test="$this-row[starts-with(name(), $cites-column-start)]">
                            <xsl:value-of
                                select="index-of($this-row/name(), $this-row/name()[starts-with(., $cites-column-start)])"
                            />
                        </xsl:if>
                    </xsl:variable>
                    <xsl:variable name="cites"
                        select="$column-mapping/cites[@column = $cites-column-position]"/>
                    <!-- checks whether source is a manuscript or regular bibliographic item -->
                    <xsl:variable name="bibl-uri-type">
                        <xsl:choose>
                            <xsl:when test="matches(name(), 'Ms_') or matches(name(), 'DigitalCatalogue_')">manuscript</xsl:when>
                            <xsl:otherwise>bibl</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="bibl-citation-format">
                        <xsl:choose>
                            <xsl:when test="matches(name(), 'Ms_')">manuscript</xsl:when>
                            <xsl:when test="matches(name(), 'DigitalCatalogue_')">digital catalogue</xsl:when>
                            <xsl:otherwise>bibl</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <!-- can change this to localhost if there is problem with dev server-->
                    <!--<xsl:variable name="server-address" select="'http://wwwb.library.vanderbilt.edu/'"/>-->
                    <xsl:variable name="server-address"
                        select="'http://localhost:8080/exist/apps/srophe/'"/>
                    <!-- creates the path to the bibl TEI using the URI number from the cell being processed -->
                    <xsl:variable name="bibl-uri-prefix"
                        select="concat('http://syriaca.org/', $bibl-uri-type, '/')"/>
                    <xsl:variable name="bibl-url">
                        <xsl:if test="matches(., '^http://syriaca.org/|^\d+')">
                            <xsl:value-of
                                select="concat($server-address, $bibl-uri-type, '/', replace(replace(., $bibl-uri-prefix, ''), '#.*$', ''), '/tei')"
                            />
                        </xsl:if>
                    </xsl:variable>


                    <!-- BIBL ELEMENT -->
                    <xsl:element name="bibl">
                        <!-- adds an @xml:id in the format "bib000-0", where 000 is the ID of this record and 0 is the number of this <bibl>  -->
                        <xsl:variable name="bib-id"
                            select="concat('bib', $record-id, '-', index-of($sources-sorted-tokenized, $source-uri-column))"/>
                        <xsl:attribute name="xml:id" select="$bib-id"/>
                        <!-- adds an RDF-friendly @type attribute to the bibl element -->
                        <xsl:choose>
                            <xsl:when test="matches(name(), 'Edition_')">
                                <xsl:attribute name="type" select="'lawd:Edition'"/>
                            </xsl:when>
                            <xsl:when test="matches(name(), 'Translation_')">
                                <xsl:attribute name="type" select="'syriaca:ModernTranslation'"/>
                            </xsl:when>
                            <xsl:when test="matches(name(), 'Version_')">
                                <xsl:attribute name="type" select="'syriaca:AncientVersion'"/>
                            </xsl:when>
                            <xsl:when test="matches(name(), 'Source_')">
                                <xsl:attribute name="type" select="'lawd:Citation'"/>
                            </xsl:when>
                            <xsl:when test="matches(name(), 'Ms_')">
                                <xsl:attribute name="type" select="'syriaca:Manuscript'"/>
                            </xsl:when>
                            <xsl:when test="matches(name(), 'PrintCatalogue_')">
                                <xsl:attribute name="type" select="'syriaca:PrintCatalogue'"/>
                            </xsl:when>
                            <xsl:when test="matches(name(), 'DigitalCatalogue_')">
                                <xsl:attribute name="type" select="'syriaca:DigitalCatalogue'"/>
                            </xsl:when>
                            <xsl:when test="matches(name(), 'Glossary_')">
                                <xsl:attribute name="type" select="'syriaca:Glossary'"/>
                            </xsl:when>
                            <xsl:when test="matches(name(), 'Apparatus_')">
                                <xsl:attribute name="type" select="'syriaca:Apparatus'"/>
                            </xsl:when>
                            <xsl:when test="matches(name(), 'OriginalWithSyriacEvidence_')">
                                <xsl:attribute name="type"
                                    select="'syriaca:OriginalWithSyriacEvidence'"/>
                            </xsl:when>
                            <xsl:when test="matches(name(), 'Literature_')">
                                <xsl:attribute name="type"
                                    select="'syriaca:Literature'"/>
                            </xsl:when>
                            <xsl:when test="matches(name(), 'ReferenceWork_')">
                                <xsl:attribute name="type"
                                    select="'syriaca:ReferenceWork'"/>
                            </xsl:when>
                        </xsl:choose>
                        <!-- grabs the title of the remote bibl record and imports it here. -->
                        <!-- ??? What info do we want to include here - just the title or more? The title of the TEI doc or the title of the described bibl? -->
                        <xsl:choose>
                            <xsl:when test="string-length($bibl-url)">
                                <xsl:choose>
                                    <xsl:when test="$bibl-uri-type = 'bibl'">
                                        <xsl:copy-of
                                            select="document($bibl-url)/TEI/teiHeader/fileDesc/titleStmt/title"
                                            xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>
                                    </xsl:when>
                                    <xsl:when test="$bibl-citation-format = 'manuscript'">
                                        <xsl:variable name="ms-doc" select="document($bibl-url)"/>
                                        <xsl:variable name="ms-identifier"
                                            select="$ms-doc//tei:msIdentifier[1]"/>
                                        <xsl:variable name="title-prefix"
                                            select="string-join(($ms-identifier/tei:settlement, $ms-identifier/tei:repository, $ms-identifier/tei:collection), ', ')"/>
                                        <xsl:variable name="alt-id-shelfmark-types"
                                            select="('BL-Shelfmark', 'Shelfmark', 'Accession-number', 'Shelfmark_1', 'Shelfmark_2', 'Bookplate')"/>
                                        <xsl:variable name="shelfmark"
                                            select="$ms-identifier/tei:altIdentifier/tei:idno[@type = $alt-id-shelfmark-types]"/>
                                        <title>
                                            <xsl:value-of
                                                select="string-join(($title-prefix, $shelfmark), ', ')"
                                            />
                                        </title>
                                        <!-- ??? could also put date here - see date handling from create-works-from-matched-mss-2.xql -->
                                        <!-- ??? need to add handling for automatic insertion of relevant Wright and digital Wright catalogue citations. 
                                            see create-works-from-matched-mss-2.xql or example http://syriaca.org/work/1 -->
                                    </xsl:when>
                                    <xsl:when test="$bibl-citation-format = 'digital catalogue'">
                                        <editor role="general-editor"
                                            ref="http://syriaca.org/documentation/editors.xml#dmichelson"
                                            >David A. Michelson</editor>
                                        <xsl:copy-of
                                            select="document($bibl-url)/TEI/teiHeader/fileDesc/titleStmt/title"
                                            xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>
                                        <title level="m" xml:lang="en">A Digital Catalogue of
                                            Syriac Manuscripts in the British Library</title>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise>
                                <title>
                                    <xsl:value-of select="."/>
                                </title>
                            </xsl:otherwise>
                        </xsl:choose>
                        <!-- adds a pointer with this bibl's URI -->
                        <xsl:variable name="this-bibl-id" select="."/>
                        <xsl:if test="string-length($bibl-url)">
                            <ptr>
                                <xsl:attribute name="target">
                                    <xsl:choose>
                                        <xsl:when test="starts-with(., 'http://syriaca.org')">
                                            <xsl:value-of select="."/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of
                                                select="concat('http://syriaca.org/', $bibl-uri-type, '/', replace($this-bibl-id,'#.*$',''))"
                                            />
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                            </ptr>
                        </xsl:if>
                        <!-- cycles through citedRange(s) and adds to bibl. This accepts multiple citedRanges for the same bibl (e.g., both page and section numbers), 
                                if they exist. -->
                        <xsl:for-each select="$cited-ranges">
                            <xsl:variable name="this-cited-range" select="."/>
                            <xsl:variable name="this-cited-range-content"
                                select="$this-row[name() = $this-cited-range/@column or position() = $this-cited-range/@column]"/>
                            <xsl:if
                                test="not(matches($this-cited-range-content, '^\s*[Nn][Oo][Nn][Ee]\s*$')) and string-length($this-cited-range-content)">
                                <xsl:variable name="this-cited-range-URL">
                                    <xsl:analyze-string select="$this-cited-range-content"
                                        regex="\[(https?://.*)\]">
                                        <xsl:matching-substring>
                                            <xsl:value-of select="regex-group(1)"/>
                                        </xsl:matching-substring>
                                    </xsl:analyze-string>
                                </xsl:variable>
                                <xsl:variable name="this-cited-range-non-URL"
                                    select="replace($this-cited-range-content, '\s*\[https?://.*\]\s*', '')"/>
                                <xsl:element name="citedRange">
                                    <xsl:attribute name="unit" select="$this-cited-range/@unit"/>
                                    <!-- adds URI of citedRange to @target
                                        expects URI for citedRange in square brackets, e.g., [http://archive.org/...] -->
                                    <xsl:if test="$this-cited-range-URL != ''">
                                        <xsl:attribute name="target" select="$this-cited-range-URL"
                                        />
                                    </xsl:if>
                                    <!-- gets the value of the cited range cell in the spreadsheet whose column name or position matches the @column 
                                            defined in $column-mapping/citedRange -->
                                    <xsl:value-of
                                        select="normalize-space($this-cited-range-non-URL)"/>
                                </xsl:element>
                            </xsl:if>
                        </xsl:for-each>
                        <xsl:if test="$bibl-citation-format = 'digital catalogue'">
                            <xsl:variable name="ms-doc" select="document($bibl-url)"/>
                            <xsl:variable name="ms-item" select="$ms-doc//*[@xml:id=replace($this-bibl-id,'^.*?#','')]"/>
                            <publisher>Syriaca.org</publisher>
                            <date>forthcoming</date>
                            <citedRange unit="entry"
                                target="{concat('http://syriaca.org/',$bibl-uri-type,'/',$this-bibl-id)}"><xsl:value-of select="$ms-item/tei:title[1]"/></citedRange>
                        </xsl:if>
                        <!-- cycles through bibl-note(s) and adds to bibl. This accepts multiple bibl-notes for the same bibl, 
                                if they exist. -->
                        <xsl:for-each select="$bibl-notes">
                            <xsl:variable name="this-bibl-note" select="."/>
                            <xsl:variable name="this-bibl-note-content"
                                select="$this-row[name() = $this-bibl-note/@column or position() = $this-bibl-note/@column]"/>
                            <xsl:if
                                test="not(matches($this-bibl-note-content, '^\s*[Nn][Oo][Nn][Ee]\s*$')) and string-length($this-bibl-note-content)">
                                <xsl:element name="note">
                                    <!-- gets the value of the bibl-note cell in the spreadsheet whose column name or position matches the @column 
                                            defined in $column-mapping/citedRange -->
                                    <xsl:value-of select="normalize-space($this-bibl-note-content)"
                                    />
                                </xsl:element>
                            </xsl:if>
                        </xsl:for-each>
                        <xsl:if
                            test="matches(., '#') and not(string-length(string-join($this-row[name() = $cited-ranges/@column or position() = $cited-ranges/@column], '')))">
                            <xsl:variable name="msItem-id" select="replace(., '^.*#', '')"/>
                            <xsl:variable name="locus">
                                <xsl:copy-of
                                    select="document($bibl-url)/TEI//msItem[@xml:id = $msItem-id]/locus"
                                    xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>
                            </xsl:variable>
                            <xsl:if test="$locus">
                                <xsl:element name="citedRange">
                                    <xsl:attribute name="unit" select="'folio'"/>
                                    <xsl:attribute name="from" select="$locus/tei:locus/@from"/>
                                    <xsl:attribute name="to" select="$locus/tei:locus/@to"/>
                                    <xsl:value-of select="$locus"/>
                                </xsl:element>
                            </xsl:if>
                        </xsl:if>
                        <!-- adds the lang when present -->
                        <xsl:for-each select="$langs">
                            <xsl:variable name="this-lang" select="."/>
                            <xsl:variable name="this-lang-content"
                                select="$this-row[name() = $this-lang/@column or position() = $this-lang/@column]"/>
                            <xsl:variable name="tokenized-langs"
                                select="tokenize($this-lang-content, ',\s*')"/>
                            <xsl:for-each select="$tokenized-langs">
                                <xsl:element name="lang">
                                    <xsl:value-of select="."/>
                                </xsl:element>
                            </xsl:for-each>
                        </xsl:for-each>
                        <!-- adds witnesses when present -->
                        <xsl:if
                            test="matches(name(), 'Edition_|Translation_|Version_|Ms_') or $witnesses or $cites">
                            <listRelation>
                                <xsl:for-each select="$witnesses">
                                    <xsl:variable name="this-witness" select="."/>
                                    <xsl:variable name="witness-content"
                                        select="$this-row[name() = $this-witness/@column or position() = $this-witness/@column]"/>
                                    <xsl:if test="string-length($witness-content)">
                                        <xsl:variable name="witnesses-tokenized"
                                            select="tokenize(replace($witness-content, '\s', '_'), ',_?')"/>
                                        <xsl:variable name="witnesses-source-bib-id">
                                            <xsl:if test="$this-witness/@sourceUriColumn">
                                                <xsl:value-of
                                                  select="concat('bib', $record-id, '-', index-of($sources-sorted-tokenized, $this-witness/@sourceUriColumn))"
                                                />
                                            </xsl:if>
                                        </xsl:variable>
                                        <!--<xsl:variable name="witnesses-source-bib-id" select="concat('bib',$record-id,'-',index-of($sources-sorted-tokenized,$this-witness/@sourceUriColumn))"/>-->
                                        <xsl:variable name="witness-bib-ids">
                                            <xsl:for-each select="$witnesses-tokenized">
                                                <xsl:copy-of
                                                  select="concat('#bib', $record-id, '-', index-of($sources-sorted-tokenized, .))"
                                                />
                                            </xsl:for-each>
                                        </xsl:variable>
                                        <!-- ??? Should we drop relation/@type since "mssWitnesses", "translationSource", etc. don't really handle 
                                    situations where an edition is using another edition and so on? -->
                                        <xsl:element name="relation">
                                            <xsl:attribute name="active"
                                                select="concat('#', $bib-id)"/>
                                            <xsl:attribute name="ref" select="'dcterms:source'"/>
                                            <xsl:attribute name="passive" select="$witness-bib-ids"/>
                                            <xsl:if test="string-length($witnesses-source-bib-id)">
                                                <xsl:attribute name="source"
                                                  select="concat('#', $witnesses-source-bib-id)"/>
                                            </xsl:if>
                                        </xsl:element>
                                    </xsl:if>
                                </xsl:for-each>
                                <xsl:for-each select="$cites">
                                    <xsl:variable name="this-cites" select="."/>
                                    <xsl:variable name="cites-content"
                                        select="$this-row[name() = $this-cites/@column or position() = $this-cites/@column]"/>
                                    <xsl:if test="string-length($cites-content)">
                                        <xsl:variable name="cites-tokenized"
                                            select="tokenize(replace($cites-content, '\s', '_'), ',_?')"/>
                                        <xsl:variable name="cites-source-bib-id">
                                            <xsl:if test="$this-cites/@sourceUriColumn">
                                                <xsl:value-of
                                                  select="concat('bib', $record-id, '-', index-of($sources-sorted-tokenized, $this-cites/@sourceUriColumn))"
                                                />
                                            </xsl:if>
                                        </xsl:variable>
                                        <!--<xsl:variable name="cites-source-bib-id" select="concat('bib',$record-id,'-',index-of($sources-sorted-tokenized,$this-cites/@sourceUriColumn))"/>-->
                                        <xsl:variable name="cites-bib-ids">
                                            <xsl:for-each select="$cites-tokenized">
                                                <xsl:copy-of
                                                  select="concat('#bib', $record-id, '-', index-of($sources-sorted-tokenized, .))"
                                                />
                                            </xsl:for-each>
                                        </xsl:variable>
                                        <!-- ??? Should we drop relation/@type since "mssWitnesses", "translationSource", etc. don't really handle 
                                    situations where an edition is using another edition and so on? -->
                                        <!-- !!! Only grabs bib id of item rather than grabbing the ptr/@target URI (which would be better)  -->
                                        <xsl:for-each select="tokenize($cites-bib-ids, '\s')">
                                            <xsl:element name="relation">
                                                <xsl:attribute name="active" select="."/>
                                                <xsl:attribute name="ref"
                                                  select="'lawd:hasCitation'"/>
                                                <xsl:attribute name="passive"
                                                  select="concat('#', $bib-id)"/>
                                                <xsl:if test="string-length($cites-source-bib-id)">
                                                  <xsl:attribute name="source"
                                                  select="concat('#', $cites-source-bib-id)"/>
                                                </xsl:if>
                                            </xsl:element>
                                        </xsl:for-each>
                                    </xsl:if>
                                </xsl:for-each>
                                <xsl:if test="matches(name(), 'Edition_|Translation_|Version_|Ms_')">
                                    <xsl:element name="relation">
                                        <xsl:attribute name="active" select="concat('#', $bib-id)"/>
                                        <xsl:attribute name="ref" select="'lawd:embodies'"/>
                                        <xsl:attribute name="passive"
                                            select="concat('http://syriaca.org/work/', $record-id)"
                                        />
                                    </xsl:element>
                                </xsl:if>
                            </listRelation>
                        </xsl:if>

                    </xsl:element>
                </xsl:if>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>

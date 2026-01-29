<cfdocument format="pdf" filename="#expandPath("./temp/")#mydoc.pdf">
    <h1>Hello ColdFusion</h1>
    <p>This is <strong>PDF</strong> example document.</p>
    <p>Generated at: <cfoutput>#TimeFormat(Now())# on #DateFormat(Now())#</cfoutput></p>
</cfdocument>
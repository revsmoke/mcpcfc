<cftry>
    <cfdocument format="pdf" filename="mydoc.pdf">
        <h1>Hello ColdFusion</h1>
        <p>This is <strong>PDF</strong> example document.</p>
        <p>Generated at: <cfoutput>#TimeFormat(Now())# on #DateFormat(Now())#</cfoutput></p>
    </cfdocument>
    <cfcatch type="any">
        <cfoutput>
            <p>Error: #cfcatch.message#</p>
            <p>Error details: #cfcatch.detail#</p>
            <p>Error type: #cfcatch.type#</p>
            <p>Error stack: #cfcatch.stacktrace#</p>
        </cfoutput>
    </cfcatch>
    </cftry>
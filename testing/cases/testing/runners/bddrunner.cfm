<cfsetting showdebugoutput="false" >
<cfparam name="url.reporter" default="simple"> 
<!--- One runner --->
<cfset r = new coldbox.system.testing.runners.BDDRunner( "coldbox.testing.cases.testing.specs.BDDTest" ) >
<cfoutput>#r.run(reporter="#url.reporter#")#</cfoutput>
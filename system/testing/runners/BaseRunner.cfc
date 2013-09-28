/**
********************************************************************************
Copyright 2005-2009 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************
* The TestBox main base runner which has all the common methods needed for runner implementations.
*/ 
component accessors="true"{
	
	// The CFC bundles to test
	property name="bundles";
	// The labels used for the testing
	property name="labels";
	// The main utility object
	property name="utility";
	// The reporter attached to this runner
	property name="reporter";
	// The version
	property name="version";
	// The codename
	property name="codename";
			
	/**
	* Constructor
	* @bundles.hint The path, list of paths or array of paths of the spec bundle CFCs to run and test
	* @directory.hint The directory information struct to test: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the CFC found, it must return true to process or false to continue process ]
	* @reporter.hint The type of reporter to use for the results, by default is uses our 'simple' report. You can pass in a core reporter string type or an instance of a coldbox.system.testing.reports.IReporter
	* @labels.hint The list or array of labels that a suite or spec must have in order to execute.
	*/
	any function init( any bundles=[], struct directory={}, any reporter="simple", any labels=[] ){
		// TestBox version
		variables.version 	= "1.0.0.@build.number@";
		variables.codename 	= ""; 
		// init util
		variables.utility = new coldbox.system.core.util.Util();
		// reporter
		variables.reporter = arguments.reporter;

		// directory passed?
		if( !structIsEmpty( arguments.directory ) ){
			arguments.bundles = getSpecPaths( arguments.directory );
		}
		// inflate labels
		variables.labels = ( isSimpleValue( arguments.labels ) ? listToArray( arguments.labels ) : arguments.labels ); 
		// inflate bundles to array
		inflateBundles( arguments.bundles );
		
		return this;
	}
	
	/************************************** REPORTING COMMON METHODS *********************************************/

	/**
	* Build a report according to this runner's setup reporter, which can be anything.
	* @results.hint The results object to use to produce a report
	*/
	private any function produceReport( required results ){
		// if reporter is simple value, then its a core reporter, go get it
		if( isSimpleValue( variables.reporter ) ){
			variables.reporter = buildReporter( variables.reporter );
		}
		// build the report from the reporter
		return variables.reporter.runReport( arguments.results, this );
	}

	/**
	* Build a reporter according to passed in reporter type or class path
	* @reporter.hint The reporter type to build.
	*/
	private any function buildReporter( required reporter ){
		var reporterList = "json,raw,simple,dot";

		switch( arguments.reporter ){
			case "json" : { return new "coldbox.system.testing.reports.JSONReporter"(); }
			case "raw" : { return new "coldbox.system.testing.reports.RawReporter"(); }
			case "simple" : { return new "coldbox.system.testing.reports.SimpleReporter"(); }
			case "dot" : { return new "coldbox.system.testing.reports.DotReporter"(); }
			default: {
				return new "#arguments.reporter#"();
			}
		}
	}


	/************************************** DISCOVERY METHODS *********************************************/
	
	

	/************************************** UTILITY METHODS *********************************************/

	/**
	* Creates and returns a bundle CFC with spec capabilities if not inherited.
	* @bundlePath.hint The path to the Bundle CFC
	*/ 
	private any function getBundle( required bundlePath ){
		var bundle		= new "#arguments.bundlePath#"();
		var familyPath 	= "coldbox.system.testing.BaseSpec";
		
		// check if base spec assigned
		if( isInstanceOf( bundle, familyPath ) ){
			return bundle;
		}
		
		// Else virtualize it
		var baseObject 			= new coldbox.system.testing.BaseSpec();
		var excludedProperties 	= "";
		
		// Mix it up baby
		variables.utility.getMixerUtil().start( bundle );
		
		// Mix in the virtual methods
		for( var key in baseObject ){
			// If target has overriden method, then don't override it with mixin, simulated inheritance
			if( NOT structKeyExists( bundle, key ) AND NOT listFindNoCase( excludedProperties, key ) ){
				bundle.injectMixin( key, baseObject[ key ] );
			}
		}

		// Mix in virtual super class just in case we need it
		bundle.$super = baseObject;
		
		return bundle;
	}

	/**
	* Validate the incoming method name is a valid TestBox test method name
	*/
	private boolean function isValidTestMethod( required methodName ) {
		// All test methods must start with the term, "test". 
		return( !! reFindNoCase( "^test", methodName ) );
	}
	
	/**
	* Inflate incoming bundles from a simple string as a standard array
	*/
	private function inflateBundles(required any bundles){
		variables.bundles = ( isSimpleValue( arguments.bundles ) ? listToArray( arguments.bundles ) : arguments.bundles );
	}

	/**
	* Get an array of spec paths from a directory
	* @directory.hint The directory information struct to test: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the CFC found, it must return true to process or false to continue process ]
	*/
	private function getSpecPaths( required directory ){
		var results = [];

		// recurse default
		arguments.directory.recurse = ( structKeyExists( arguments.directory, "recurse" ) ? arguments.directory.recurse : true );
		// clean up paths
		var bundleExpandedPath 	= expandPath( "/" & replace( arguments.directory.mapping, ".", "/", "all" ) );
		bundleExpandedPath 		= replace( bundleExpandedPath, "\", "/", "all" );
		// search directory with filters
		var bundlesFound 		= directoryList( bundleExpandedPath, arguments.directory.recurse, "path", "*.cfc", "asc" );

		// cleanup paths and store them for usage
		for( var x=1; x lte arrayLen( bundlesFound ); x++ ){

			// filter closure exists and the filter does not match the path
			if( structKeyExists( arguments.directory, "filter" ) && !arguments.directory.filter( bundlesFound[ x ] ) ){
				continue;
			}

			// standardize paths
			bundlesFound[ x ] = rereplace( replaceNoCase( bundlesFound[ x ], ".cfc", "" ) , "(\\|/)", "/", "all" );
			// clean base out of them
			bundlesFound[ x ] = replace( bundlesFound[ x ], bundleExpandedPath, "" );
			// Clean out slashes and append the mapping.
			bundlesFound[ x ] = arguments.directory.mapping & rereplace( bundlesFound[ x ], "(\\|/)", ".", "all" );

			arrayAppend( results, bundlesFound[ x ] );
		}

		return results;
	}
	
	
}
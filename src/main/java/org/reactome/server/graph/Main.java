package org.reactome.server.graph;

import com.martiansoftware.jsap.*;
import org.reactome.server.graph.batchimport.ReactomeBatchImporter;

import java.io.File;
import java.io.IOException;

/**
 * @author Florian Korninger (florian.korninger@ebi.ac.uk)
 */
public class Main {

    public static void main(String[] args) throws JSAPException, IOException {
        SimpleJSAP jsap = new SimpleJSAP(Main.class.getName(), "A tool for importing reactome data import to the neo4j graphDb",
                new Parameter[]{
                        new FlaggedOption(  "host",         JSAP.STRING_PARSER,   "localhost",          JSAP.NOT_REQUIRED, 'h', "host",         "The database host"),
                        new FlaggedOption(  "port",         JSAP.INTEGER_PARSER,  "3306",               JSAP.NOT_REQUIRED, 's', "port",         "The reactome port"),
                        new FlaggedOption(  "name",         JSAP.STRING_PARSER,   "reactome",           JSAP.NOT_REQUIRED, 'd', "name",         "The reactome database name to connect to"),
                        new FlaggedOption(  "user",         JSAP.STRING_PARSER,   "reactome",           JSAP.NOT_REQUIRED, 'u', "user",         "The database user"),
                        new FlaggedOption(  "password",     JSAP.STRING_PARSER,   "reactome",           JSAP.NOT_REQUIRED, 'p', "password",     "The password to connect to the database"),
                        // TODO - remove the deprecated option and set the neo4j option default by 2019.
                        new FlaggedOption("neo4j_deprecated", JSAP.STRING_PARSER, "./target/graph.db", JSAP.NOT_REQUIRED, 'n', "neo4j_deprecated", "Path to the target Neo4j database"),
                        new FlaggedOption("neo4j",    JSAP.STRING_PARSER,   JSAP.NO_DEFAULT, JSAP.NOT_REQUIRED, 'o', "neo4j",    "Path to the target Neo4j database"),
                        new FlaggedOption(  "intactFile",   JSAP.STRING_PARSER,   JSAP.NO_DEFAULT,          JSAP.NOT_REQUIRED, 'f', "intactFile",   "Path to the interaction data file"),
                        new QualifiedSwitch("interactions", JSAP.BOOLEAN_PARSER,  JSAP.NO_DEFAULT,          JSAP.NOT_REQUIRED, 'i', "interactions", "Include interaction data. If the intactFile is not provided, the interaction data will be downloaded"),
                        new QualifiedSwitch("bar",          JSAP.BOOLEAN_PARSER,  JSAP.NO_DEFAULT,          JSAP.NOT_REQUIRED, 'b', "bar",          "Forces final status")
                }
        );

        JSAPResult config = jsap.parse(args);
        if (jsap.messagePrinted()) System.exit(1);

        //If only interactions flag is set up, the graph-importer will download the interaction data from IntAct
        //The user can specify a location of the file with the interaction content and that will be used
        boolean includeInteractions = config.getBoolean("interactions");
        String intactFile = config.getString("intactFile");
        if(intactFile != null && !intactFile.isEmpty()){
            File f = new File(intactFile);
            if(!f.exists() || f.isDirectory()) {
                System.err.println(intactFile + " does not exist or it is a directory. Please provide the path to the interaction database");
                System.exit(1);
            }
            includeInteractions = true;
        }

        /*
         * TODO - should this comment block be deleted?
         * 
         * @Autowired annotation does not work in a static context. context.getBean has to be used instead.
         * final AnnotationConfigApplicationContext ctx = new AnnotationConfigApplicationContext(MyConfiguration.class);
         * ReactomeBatchImporter batchImporter = ctx.getBean(ReactomeBatchImporter.class);
         */
        String targetDir = config.getString("neo4j");
        if (targetDir == null || targetDir.isEmpty()) {
            targetDir = config.getString("neo4j_deprecated");
        }
        ReactomeBatchImporter batchImporter = new ReactomeBatchImporter(
                config.getString("host"),
                config.getInt("port"),
                config.getString("name"),
                config.getString("user"),
                config.getString("password"),
                targetDir,
                includeInteractions, intactFile
        );
        batchImporter.importAll(!config.getBoolean("bar"));
    }
}
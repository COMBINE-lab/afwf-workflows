
# 10x Chromium 3' v2 gene expression data processing
# https = #combine-lab.github.io/alevin-fry-tutorials/2023/simpleaf-piscem/
#############################################################################
# README = 
# *IMPORTANT* =  For most user, the fields in section "Recommended Configuration" are the only things to complete.
# To modify an argument, please replace the Right hand side of each field (separated by ` = `) with your value **wrapped in quotes**.
# For example, you can replace `"output" =  null` in the meta_info section with `"output": "/path/to/output/dir"`, and `"threads": null` with `"threads": "16"`
# All fields that are null, empty array ([]), and empty dictionary ({}) will be pruned (ignored).
# NOTE =  You can pass optional simpleaf arguments specified in the "Optional Configuration" section.
#############################################################################
let utils = import "type-schemas.ncl" in 
let workflow = {

    # Meta information about the workflow
    meta-info = {
        template_name | String = "10x Chromium 3' v2 gene expression",
        template_id | String = "10x-chromium-3p-v2",
        template_version | String = "0.0.1",

        # This value will be assigned to all simpleaf commands that have no --threads arg specified
        # Optional =  commands will use their default setting if this is null.
        threads 
          | doc m%"
          this value will be assigned to all simpleaf commands that have no --threads
          arg specified. Optional commands will use their default setting if this is null.
          "%
          | utils.NumberOrNull
          | default = null, 
        
        output 
          | doc m%"
          The parent directory of all simpleaf command output folders.
          If this is left as null, you must specify `--output` when running `simpleaf workflow`
          "%
          | optional
          | default = "", 

        # this meta flag says if piscem, instead of the default choice salmon, should be used for indexing and mapping for all applicable simpleaf commands.
        use-piscem
          | Bool
          | doc "if true, use piscem rather than salmon; if false use salmon"
          | default = true,

    },

    #######################################################################################################################
    # *Recommended* Configuration =  
    #  For MOST users, the fields listed in the "Recommended Configuration" section are the only fields
    #  that needs to be filled. You should replace all null values with valid values, 
    #  as described in the comment lines (those start with double slashes `#`) .
    # For advanced users, you can check other simpleaf arguments listed in the "Optional Configurtion" section.
    ######################################################################################################################
        
    # **For most users**, ONLY the information in the "Recommended Configuration" section needs to be completed.
    # For advanced usage, please check the "Optional Configuration" field.
    recommended-config 
      | not_exported = {

        simpleaf_index_params | not_exported = {
          custom-ref-gtf 
            | doc "If using the splici or spliceu reference, use this gtf"
            = null,

          custom-ref-fasta
            | doc "If using the splici or spliceu reference, use this fasta"
            = null,

        },
        #Information for running `simpleaf quant`
        simpleaf_quant_params | not_exported = {
            # read1 (technical reads) files separated by comma (,)
            # having multiple files and they are all in a directory? try the following bash command to get their name (Don't forget to quote them!)
            # $ find -L your/fastq/absolute/path -name "*_R1_*" -type f | sort | paste -sd, -
            # Change "*_R1_*" to the file name pattern of your files if it dosn't fit
            reads1
              | not_exported = null,
 
            # read2 (biological reads) files separated by comma (,)
            # having multiple files and they are all in a directory? try the following bash command to get their name (Don't forget to quote them!)
            # $ find -L your/fastq/absolute/path -name "*_R1_*" -type f | sort | paste -sd, -
            # Change "*_R1_*" to the file name pattern of your files if it dosn't fit
            reads2 
              | not_exported = null,
        },
       

        # Arguments for running `simpleaf index`
        simpleaf_index = {
            # these two fields are required for all command records.
            step | Number = 1,
            program-name | String = "simpleaf index",
        } & optional-config.simpleaf_index_params.reference-info,

        simpleaf_quant = {
            step | Number = 2,
            program-name | String = "simpleaf quant",
        } & optional-config.simpleaf_quant_params.mapping-params
    },

    ##########################################################################################################
    # OPTIONAL  =  The configuration options below are optional, and may be of most interest to advanced users

    # If you want tyo skip invoking some commands, for example, when the exactly same command had been run before, 
    # you can also change their "Active" to false.
    # Simpleaf will ignore all commands with "Active" =  false
    #########################################################################################################
    optional-config | not_exported =  {

        simpleaf_index_params | not_exported = {
          ## need the below defined here for simpleaf_index, as they 
          # need to be merged with that record.
          #
          # This selects what type of reference will be built. If you 
          # want to use the default recommended index type (currently splici),
          # then you can leave this value as is, and fill in the 
          # splici-params field below as appropriate
          reference-type 
            | not_exported
            | doc "The type of reference to create"
            | [| 'splici, 'spliceu, 'direct-ref |]
            | default = 'splici,

          splici-params | not_exported = {
            "--fasta" 
              | doc "genome fasta file of the studied species"
              = recommended-config.simpleaf_index_params.custom-ref-fasta,

            "--gtf" 
              | doc "gene annotation gtf file of the studied species"
              = recommended-config.simpleaf_index_params.custom-ref-gtf,

            "--rlen" 
              | Number 
              | doc m%"
              read length, usually it is "98" for 10xv2 datasets.
              Please check the description of your experiment to make sure
              "% 
              | default = 98,
            },

          # Recommeneded Reference =  spliced + intronic transcriptome (splici) 
          # https = #pyroe.readthedocs.io/en/latest/building_splici_index.html#preparing-a-spliced-intronic-transcriptome-reference
          # You can find other reference options in the "Optional Configuration" field. You must choose one type of reference
          reference-info 
            | not_exported
            | doc m%"
            How the reference that is indexed and mapped against is obtained. This will be an entry 
            with the necessary information to create a splici (spliced+intronic) or spliceu (spliced+unspliced)
            reference, or will be a "direct-reference" with the information on the target sequences to 
            index directly.
            "%
            = reference-type |> match {
              'splici => splici-params,
                'spliceu => optional-config.simpleaf_index.spliceu-params,
                'direct-ref => optional-config.simpleaf_index.direct-ref-params
            }
        },

        # Optioanal arguments for running `simpleaf index`
        simpleaf_index =  {
            active | Bool =  true,

            spliceu-params | not_exported = {
                # spliced + unspliced transcriptome
                # https = //pyroe.readthedocs.io/en/latest/building_splici_index.html#preparing-a-spliced-unspliced-transcriptome-reference
                # specify reference type as spliced+unspliced (spliceu)
                "--ref-type" =  "spliceu", # "--ref-type": "spliced+unspliced",
                # The path to the genome FASTA file
                "--fasta" =  recommended-config.simpleaf_index_params.custom-ref-fasta,
                # The path to the gene annotation GTF file
                "--gtf" =  recommended-config.simpleaf_index_params.custom-ref-gtf,
            },

            direct-ref-params
                  | doc m%"
                  Direct Reference
                  If the species doesn"t have its genome available,
                  you can pass the reference sequence FASTA file as `--ref-seq`.
                  simpleaf will build index directly using the given file 
                  "% 
                  | not_exported = {
                    "--ref-seq" 
                    | doc "The path to the reference sequence FASTA file" 
                    =  null,
            },

            # These are optional parameters. If values are assigned to them 
            # then they will be used, otherwise default values will be filled 
            # in from the utility template.
            "--output" =  "%{meta-info.output}/simpleaf_index/index",
            "--spliced" | optional,
            "--unspliced" | optional,
            "--threads" =  meta-info.threads,
            "--dedup" | Bool | optional,
            "--sparse" | Bool | optional,
            "--kmer-length" | optional,
            "--overwrite" | optional,
            "--use-piscem" =  meta-info.use-piscem,
            "--minimizer-length" | optional,
            "--keep-duplicates" | Bool | optional,
        },

        simpleaf_quant_params | not_exported = {

          # will be used below in simpleaf_quant but needs to 
          # be dealt with here because it will be merged in
          mapping-type
            | [| 'map-reads, 'existing-mappings |]
            | not_exported
            | default = 'map-reads,

          # Recommended Mapping Option =  Mapping reads against the splici reference generated by the simpleaf index command above.
          # Other mapping options can be found in the "Optional Configuration" section
          map-reads-params | not_exported = {
            "--index" = "%{meta-info.output}/simpleaf_index/index",
            "--reads1" = reads1,
            "--reads2" = reads2,
          },

          mapping-params | not_exported = mapping-type |> match {
            'map-reads => map-reads-params,
            'existing-mappings => optional-config.simpleaf_quant.existing-mappings-params
          }

          cell-filtering-type 
            | not_exported
            | [| 'unfiltered-pl, 'knee, 'forced, 'expect, 'explicit-pl |]
            | default = 'unfiltered-pl,

          cell-filtering-params = 
            cell-filtering-type |> match {
              'unfiltered-pl => unfiltered-pl-params,
              'knee => knee-params,
              'forced => forced-params,
              'expect => expect-params,
              'explicit-pl => explicit-pl-params
            },

          # No cell filtering, but correct cell barcodes according to a permitlist file
          # If you would like to use other cell filtering options, please change this field to null,
          # and select one cell filtering strategy listed in the "Optional Configuration section"
          # DEFAULT
          unfiltered-pl-params | not_exported = {
            "--unfiltered-pl" =  "", # or "--unfiltered-pl": null 
          },

          # 2. knee finding cell filtering. If choosing this, change the value from null to "".
          knee-params | not_exported = {
            "--knee" =  null, # or "--knee": "",
          },

          # 3. A hard threshold. If choosing this, change the value from null to an integer
          forced-params | not_exported = {
            "--forced-cells" =  null, # or "--forced-cells": "INT", for example, "--forced-cells": "3000"
          },

          # 4. A soft threshold. If choosing this, change the null to an integer
          expect-params | not_exported = {
            "--expect-cells" =  null, #or "--expect-cells": "INT", for example, "--expect-cells": "3000"
          },

          # 5. filter cells using an explicit whitelist. Only use when you know exactly the 
          # true barcodes. 
          # If choosing this, change the null to the path to the whitelist file. 
          explicit-pl-params | not_exported = {
            "--explicit-pl" =  null, # or "--explicit-pl": "/path/to/pl",
          },
        },

        # arguments for running `simpleaf quant`
        simpleaf_quant =  {
            # The required fields first 
            # already defined in the recommended options
            # no need to redefine here
            #step =  2,
            #"program name" =  "simpleaf quant",
            #active =  true,

            # the transcript name to gene name mapping TSV file.
            # Simpleaf will find the correct t2g map file for splici and spliceu reference.
            # This is required ONLY if `--ref-seq` is specified in the corresponding simpleaf index command,
            # or if a custom index is being used.
            "--t2g-map" 
              | optional,

            # Option 2 = 
            # Choose only if you have an existing mapping directory and don"t want to rerun mapping
            existing-mappings-params | not_exported =  {
                # the path to an existing salmon/piscem mapping result directory
                "--map-dir" =  null,
            },
            
            
                "--chemistry" | String =  "10xv2",
                "--resolution" | String =  "cr-like",
                "--expected-ori" | String =  "fw",

                # If null, this argument will be automatically completed by the template.
                "--output" = "%{meta-info.output}/simpleaf_quant",

                # If "--threads" is null but the "threads" meta info field is not,
                # "threads" meta data will be used to complete this "--threads".
                "--threads" =  meta-info.threads,
                "--min-reads" | optional,
        } & simpleaf_quant_params.cell-filtering-params,
      },

      workflow = recommended-config & optional-config & utils.optional-config,
} 
in workflow

using JumpanScriptLib;
using Mono.Options;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace JumpmanCompiler
{
    public class Program
    {
        static void Main(string[] args)
        {
            string appName = AppDomain.CurrentDomain.FriendlyName;
            string outputDirectory = Environment.CurrentDirectory;
            bool helpRequested = false;
            bool verboseOutputRequested = false;

            var optionSet = new OptionSet()
            {
                string.Format("Usage: {0} [OPTIONS] filename [filename ...]", appName),
                "",
                "Compile jumpman scripting language files (.jms files).",
                "",
                "  filename                   the path to a source file(s) to compile.",
                "",
                "Options:",
                { "o|out=", "the {DIRECTORY} to place compiler output.", value => outputDirectory = value },
                { "v|verbose", "write out extended runtime debug information.", value => verboseOutputRequested = value != null },
                { "h|help", "show this help message and exit.", value => helpRequested = value != null },
            };

            List<string> extra;
            try
            {
                extra = optionSet.Parse(args);
            }
            catch (OptionException e)
            {
                Console.WriteLine("{0}:", appName);
                Console.WriteLine(e.ToString());
                Console.WriteLine("Try '{0} --help' for more information.", appName);
                return;
            }

            Action writeUsage = () => optionSet.WriteOptionDescriptions(Console.Out);
            var filenames = extra.Select(filename => Path.GetFullPath(filename)).ToList<string>();
            var invalidFilenames = filenames.Where(filename => !File.Exists(filename)).ToList<string>();

            if (helpRequested)
            {
                writeUsage();
                return;
            }

            if (filenames.Count < 1)
            {
                Console.WriteLine("Must specify at least one filename.");
                Console.WriteLine();
                writeUsage();
                return;
            }

            if (invalidFilenames.Any())
            {
                Console.WriteLine("Cannot find file(s):");
                foreach (string invalidFilename in invalidFilenames)
                {
                    Console.WriteLine(invalidFilename);
                }
                Console.WriteLine();

                writeUsage();
                return;
            }

            Action<string, string> logDebugMessage = (formatString, param0) =>
                {
                    if (verboseOutputRequested)
                    {
                        Console.WriteLine(formatString, param0);
                    }
                };

            var scriptCompiler = new ScriptCompiler();
            foreach (string filenameToCompile in filenames)
            {
                string scriptBaseName = Path.GetFileNameWithoutExtension(filenameToCompile);
                string sourceDirectory = Path.GetDirectoryName(filenameToCompile);
                string includeDirectory = sourceDirectory;
                string binaryOutputFilename = Path.Combine(outputDirectory, scriptBaseName + ".bin");
                string constantsOutputFilename = Path.Combine(sourceDirectory, "ref" + scriptBaseName + ".jms");

                using (FileStream fileToCompileStream = File.OpenRead(filenameToCompile))
                using (StreamReader streamReader = new StreamReader(fileToCompileStream))
                {
                    logDebugMessage("Compiling file: {0}", filenameToCompile);
                    scriptCompiler.Compile(includeDirectory, streamReader.ReadToEnd());
                    logDebugMessage("Finished compiling file: {0}", filenameToCompile);

                    logDebugMessage("Writing output binary file: {0}", binaryOutputFilename);
                    scriptCompiler.WriteBinary(binaryOutputFilename);
                    logDebugMessage("Finished writing output binary file: {0}", binaryOutputFilename);

                    logDebugMessage("Writing output constants file: {0}", constantsOutputFilename);
                    scriptCompiler.WriteConstants(constantsOutputFilename, scriptBaseName);
                    logDebugMessage("Finished writing output constants file: {0}", constantsOutputFilename);
                }
            }
        }
    }
}

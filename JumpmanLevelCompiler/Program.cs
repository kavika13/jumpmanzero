using JumpmanLevelLib;
using Mono.Options;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace JumpmanLevelCompiler
{
    class Program
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
                "Process jumpman level files (.lvl files).",
                "",
                "  filename                   the path to a source file(s) to process.",
                "",
                "Options:",
                { "o|out=", "the {DIRECTORY} to place processed output.", value => outputDirectory = value },
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

            Action<string, object> logDebugMessage = (formatString, param0) =>
            {
                if (verboseOutputRequested)
                {
                    Console.WriteLine(formatString, param0);
                }
            };

            Action<string, object, object> logDebugMessage2 = (formatString, param0, param1) =>
            {
                if (verboseOutputRequested)
                {
                    Console.WriteLine(formatString, param0, param1);
                }
            };

            long levelResourceCount = 0;
            LevelResource[] levelResources = new LevelResource[500];

            long levelObjectCount = 0;
            LevelObject[] levelObjects = new LevelObject[500];
            foreach(int index in Enumerable.Range(0, levelObjects.Length))
            {
                levelObjects[index].V = new Vertex[9];
            }

            foreach (string filenameToRender in filenames)
            {
                string sourceFilename = Path.GetFileName(filenameToRender);
                string sourceDirectory = Path.GetDirectoryName(filenameToRender);
                string scriptBaseName = null;

                logDebugMessage("Loading file: {0}", filenameToRender);
                FileRoutines.LoadLevelFromFile(sourceFilename, sourceDirectory, ref scriptBaseName, ref levelObjectCount, ref levelObjects, ref levelResourceCount, ref levelResources);
                logDebugMessage("Finished loading file: {0}", filenameToRender);

                string binaryOutputFilename = Path.Combine(outputDirectory, scriptBaseName + ".dat");
                string resourcesOutputFilename = Path.Combine(outputDirectory, scriptBaseName + "resources.jms");

                logDebugMessage2("Rendering output to binary file: {0} and resources constants to resource script: {1}", binaryOutputFilename, resourcesOutputFilename);
                FileRoutines.RenderLevelToFile(levelResourceCount, levelResources, levelObjectCount, levelObjects, scriptBaseName, sourceDirectory, outputDirectory);
                logDebugMessage2("Finished rendering output to binary file: {0} and resources constants to resource script: {1}", binaryOutputFilename, resourcesOutputFilename);
            }
        }
    }
}

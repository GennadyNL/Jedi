########################
# Solution Description #
########################
This solution contains of three parts:
1. Gherkin-based description of cases
2. PowerShell-based converter from Gherkin to JSON configuration file for PostMan
3. JSON-based configuration file for Postman

#########################
# Solution Requirements #
#########################
1. You will need PowerShell 3.0 installed on your system in order to convert Gherkin-based files into JSON configuration files for Postman
 1.1 You can check the installed PowerShell version with the following command: $PSVersionTable.PSVersion, it should return Major = 3
 1.2 PowerShell 3.0 is a requirement because ConvertTo-Json cmdlet is supported since that version only

2. Be careful with running too frequent tests of Gists API: your account can be flagged automatically by the GitHub security engine and your repositories can become hidden from public. The only way to change this will be a request to the support team that can take a day or more. It is recommended to use a separate GitHub account for test purposes.

########################
# Solution Limitations #
########################
1. The following global variables in Postman must be created manually for now:
createdGistID = <empty>
baseURL = https://api.github.com/gists

2. The PowerShell converter does not support wide range of Gherkin definitions
3. Not all supported API functions were added to the scope due to the time constraints. The extendable framework was decided to have more priority.

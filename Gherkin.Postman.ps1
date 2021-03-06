# This PowerShell script convert Gherkin-based API tests for Github Gists API into ready Postman project file
# Created by GennadyK, 2019-03
$ScriptName = "Gherkin.Postman"
$ScriptVersion = "1.0"
### Load Serializer module
Add-Type -assembly System.Web.Extensions
############ Collecting information about current path #########
$ScriptFilename = $MyInvocation.MyCommand.Name
$ScriptFilename = $ScriptFilename.Replace('.ps1', '')
$FullPath = $MyInvocation.MyCommand.Path
$CurrentPath = Split-Path $MyInvocation.MyCommand.Path
$ResultFile = "$CurrentPath\$ScriptFilename.log"
################################################################
function Time
{
    return (Get-Date -f "yyyyMMdd-HH:mm:ss.fff") # Returns date/time stamps for file names
}

function WriteLog ($String)
{
	Add-Content -path $ResultFile -Value "$(Time) $String" -ErrorAction Stop
	Write-Host "$(Time) $String"
}

function AskToken
{
	$SCRIPT:AuthToken = Read-Host -Prompt "Please enter a valid O2Auth token with Gists permission"
}

function CreateJsonObject($postmanId, $name, $UseCaseCollection){
   $PostmanResult = @{
					    info = @{
								_postman_id = $postmanId
								name = $name
								schema = "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
								}				
						auth = @{
								type = "bearer"
								bearer = @(
											@{
												key = "token"
												value = $AuthToken
												type = "string"
											}
									)
								}
						event = @(
									@{
										listen = "prerequest"
										script = @{
													id = "a2a45275-f810-474b-9ab8-4f9ec5ba4ef8"
													type = "text/javascript"
													exec = @()
												}
									}									
									@{
										listen = "test"
										script = @{
													id = "95862455-dcfd-4cd7-a31a-3a24b46cc92c"
													type = "text/javascript"
													exec = @()
												}
									}
								)
						item = $UseCaseCollection
					}	
    return $PostmanResult
}

function ProcessUseCase($GherkinUseCase)
{
    $PostmanRequest = New-Object -TypeName psobject 
	$PostmanRequest | Add-Member -MemberType NoteProperty -Name name -Value $GherkinUseCase.UseCaseName
	
	$PostmanEvent = New-Object -TypeName psobject
	$PostmanEvent | Add-Member -MemberType NoteProperty -Name listen -Value "test"
	
	$PostmanEventScript = New-Object -TypeName psobject
	$PostmanEventScript | Add-Member -MemberType NoteProperty -Name id -Value "82e9928c-3124-4d3d-8306-5e3b1f45dfdd"
	$PostmanEventScript | Add-Member -MemberType NoteProperty -Name exec -Value null
	$PostmanEventScript | Add-Member -MemberType NoteProperty -Name type -Value "text/javascript"
	
	$PostmanEvent | Add-Member -MemberType NoteProperty -Name script -Value $PostmanEventScript	
	$PostmanRequest | Add-Member -MemberType NoteProperty -Name event -Value  @($PostmanEvent)
		
	$PostmanRequestRequest = New-Object -TypeName psobject
	$PostmanRequestRequest | Add-Member -MemberType NoteProperty -Name method -Value $GherkinUseCase.Method
	$PostmanRequestRequest | Add-Member -MemberType NoteProperty -Name header -Value @()
	$PostmanRequestRequest | Add-Member -MemberType NoteProperty -Name body -Value @{
							mode = "raw"
							raw = ""
						}
						
	$PostmanRequestRequestUrl = New-Object -TypeName psobject					
	$PostmanRequestRequestUrl | Add-Member -MemberType NoteProperty -Name raw -Value "{{baseURL}}"
	$PostmanRequestRequestUrl | Add-Member -MemberType NoteProperty -Name host -Value "{{baseURL}}"									
	$PostmanRequestRequest | Add-Member -MemberType NoteProperty -Name url -Value $PostmanRequestRequestUrl
	$PostmanRequestRequest | Add-Member -MemberType NoteProperty -Name description -Value ""	
	
	$PostmanRequest | Add-Member -MemberType NoteProperty -Name request -Value $PostmanRequestRequest
	$PostmanRequest | Add-Member -MemberType NoteProperty -Name response -Value @()
	
	if ($GherkinUseCase.ActionType -eq "Create Gist")
	{
		$ExpectedResponseCode = 'tests["Status code is 201: Created"] = responseCode.code === ' + $GherkinUseCase.ExpectedResponseCode + ';'
		$ExpectedResponseTime = 'tests["Response time is acceptable (2s)"] = responseTime < ' + $GherkinUseCase.ExpectedResponseTime + ';'
		$PostmanEventScript.exec = @(
											'var jsonData = JSON.parse(responseBody);',
											'postman.setGlobalVariable("createdGistID", jsonData.id);',
											$ExpectedResponseCode,
											$ExpectedResponseTime,
											'tests["Content-Type header is set"] = postman.getResponseHeader("Content-Type");'
										)
		$PostmanRequest.request.body.raw = '{"description": "JedQA", "public": false,  "files": {  "hello_jed.lix": {   "content": "Test Data for JedQA"}}}'
	}
	
	if ($GherkinUseCase.ActionType -eq "Read Gist")
	{
		$ExpectedResponseCode = 'tests["Status code is 200"] = responseCode.code === ' + $GherkinUseCase.ExpectedResponseCode + ';'
		$ExpectedResponseTime = 'tests["Response time is acceptable (2s)"] = responseTime < ' + $GherkinUseCase.ExpectedResponseTime + ';'
		$PostmanEventScript.exec = @(
												'var jsonData = JSON.parse(responseBody);',
												$ExpectedResponseCode,
												$ExpectedResponseTime,
												'tests["Content-Type header is set"] = postman.getResponseHeader("Content-Type");'
												)
	}	
	
	if ($GherkinUseCase.ActionType -eq "Read Starred Gist")
	{
		$ExpectedResponseCode = 'tests["Status code is 200"] = responseCode.code === ' + $GherkinUseCase.ExpectedResponseCode + ';'
		$ExpectedResponseTime = 'tests["Response time is acceptable (2s)"] = responseTime < ' + $GherkinUseCase.ExpectedResponseTime + ';'
		$PostmanEventScript.exec = @(
												'var jsonData = JSON.parse(responseBody);',
												$ExpectedResponseCode,
												$ExpectedResponseTime,
												'tests["Content-Type header is set"] = postman.getResponseHeader("Content-Type");'
												)
		$PostmanRequestRequestUrl.raw = "{{baseURL}}/starred"
	    $PostmanRequestRequestUrl | Add-Member -MemberType NoteProperty -Name path -Value "starred"
	}
	
	if ($GherkinUseCase.ActionType -eq "Update (Star) Gist")
	{
		$ExpectedResponseCode = 'tests["Status code is 204: No Content"] = responseCode.code === ' + $GherkinUseCase.ExpectedResponseCode + ';'
		$ExpectedResponseTime = 'tests["Response time is acceptable (1s)"] = responseTime < ' + $GherkinUseCase.ExpectedResponseTime + ';'
		$PostmanEventScript.exec =  @(
												$ExpectedResponseCode,
												$ExpectedResponseTime,
												'tests["Content-Type header is set"] = postman.getResponseHeader("Content-Type");'
												)
		$PostmanRequestRequestUrl.raw = "{{baseURL}}/{{createdGistID}}/star"
	    $PostmanRequestRequestUrl | Add-Member -MemberType NoteProperty -Name path -Value  @(
										"{{createdGistID}}",
										"star"
									)
	}
	
	if ($GherkinUseCase.ActionType -eq "Update (Unstar) Gist")
	{
		$ExpectedResponseCode = 'tests["Status code is 204: No Content"] = responseCode.code === ' + $GherkinUseCase.ExpectedResponseCode + ';'
		$ExpectedResponseTime = 'tests["Response time is acceptable (1s)"] = responseTime < ' + $GherkinUseCase.ExpectedResponseTime + ';'
    	$PostmanEventScript.exec =  @(
												$ExpectedResponseCode,
												$ExpectedResponseTime,
												'tests["Content-Type header is set"] = postman.getResponseHeader("Content-Type");'
												)
		$PostmanRequestRequestUrl.raw = "{{baseURL}}/{{createdGistID}}/star"
	    $PostmanRequestRequestUrl | Add-Member -MemberType NoteProperty -Name path -Value  @(
										"{{createdGistID}}",
										"star"
									)
	}
	
	if ($GherkinUseCase.ActionType -eq "IsStarred Gist")
	{
		$ExpectedResponseCode = 'tests["Status code is ' + $GherkinUseCase.ExpectedResponseCode + '"] = responseCode.code === ' + $GherkinUseCase.ExpectedResponseCode + ';'
		$ExpectedResponseTime = 'tests["Response time is acceptable (1s)"] = responseTime < ' + $GherkinUseCase.ExpectedResponseTime + ';'
		$PostmanEventScript.exec =  @(
												$ExpectedResponseCode,
												$ExpectedResponseTime,
												'tests["Content-Type header is set"] = postman.getResponseHeader("Content-Type");'
												)
		$PostmanRequestRequestUrl.raw = "{{baseURL}}/{{createdGistID}}/star"
	    $PostmanRequestRequestUrl | Add-Member -MemberType NoteProperty -Name path -Value  @(
										"{{createdGistID}}",
										"star"
									)		
	}
	
	if ($GherkinUseCase.ActionType -eq "Delete Gist")
	{
		$ExpectedResponseCode = 'tests["Status code is 204: No Content"] = responseCode.code === ' + $GherkinUseCase.ExpectedResponseCode + ';'
		$ExpectedResponseTime = 'tests["Response time is acceptable (1s)"] = responseTime < ' + $GherkinUseCase.ExpectedResponseTime + ';'
		$PostmanEventScript.exec = @(
												$ExpectedResponseCode,
												$ExpectedResponseTime,
												'tests["Content-Type header is set"] = postman.getResponseHeader("Content-Type");'
												)
		$PostmanRequestRequestUrl.raw = "{{baseURL}}/{{createdGistID}}"
	    $PostmanRequestRequestUrl | Add-Member -MemberType NoteProperty -Name path -Value  @(
										"{{createdGistID}}"
									)
	}
	
	return $PostmanRequest
}

function StopExecution
{
	WriteLog "$ScriptName v$ScriptVersion has finished"
	exit
}
	
function main {
	WriteLog "$ScriptName v$ScriptVersion has started in $CurrentPath\"
	
	if ($AuthToken -eq $null)
	{
		WriteLog "CRITICAL error: auth token is unknown"
		StopExecution
	}
	
	# Search for Gherkin files in the current folder
	$GherkinFiles = Get-ChildItem -Path $CurrentPath -Filter "*.gherkin"
	foreach ($item in $GherkinFiles)
	{
		WriteLog "  Found $item"
	}

	foreach ($File in $GherkinFiles)
	{		
		# A custom object having properties of the use case
		$GherkinUseCase = New-Object -TypeName psobject 
		$GherkinUseCase | Add-Member -MemberType NoteProperty -Name UseCaseName -Value $null
		$GherkinUseCase | Add-Member -MemberType NoteProperty -Name ActionType -Value $null
		$GherkinUseCase | Add-Member -MemberType NoteProperty -Name Method -Value $null
		$GherkinUseCase | Add-Member -MemberType NoteProperty -Name ExpectedResponseCode -Value $null
		$GherkinUseCase | Add-Member -MemberType NoteProperty -Name ExpectedResponseTime -Value $null
		$GherkinUseCase | Add-Member -MemberType NoteProperty -Name ContentTypeHeader -Value $null
		$UseCaseCollection = @()
		
		$FileContent = Get-Content -Path "$CurrentPath\$item"
		$CurrentSection = $null
		
		foreach ($line in $FileContent)
		{
			if ([string]::IsNullOrEmpty($line))
			{
				if ($GherkinUseCase.ActionType -ne $null)
				{
					$UseCaseCollection += ProcessUseCase -GherkinUseCase $GherkinUseCase
					$GherkinUseCase = New-Object -TypeName psobject 
					$GherkinUseCase | Add-Member -MemberType NoteProperty -Name UseCaseName -Value $null
					$GherkinUseCase | Add-Member -MemberType NoteProperty -Name ActionType -Value $null
					$GherkinUseCase | Add-Member -MemberType NoteProperty -Name Method -Value $null
					$GherkinUseCase | Add-Member -MemberType NoteProperty -Name ExpectedResponseCode -Value $null
					$GherkinUseCase | Add-Member -MemberType NoteProperty -Name ExpectedResponseTime -Value $null
					$GherkinUseCase | Add-Member -MemberType NoteProperty -Name ContentTypeHeader -Value $null
				}
			}
			
			if ($line -like '*Scenario*')
			{
				$CurrentSection = "Scenario"
				$Filter = $Line -Split("Scenario: ")
				$GherkinUseCase.UseCaseName = $Filter[1]
				WriteLog "Property UseCaseName is set to $($GherkinUseCase.UseCaseName)"
			}
			
			if ($line -like '*When*')
			{
				$CurrentSection = "When"
				if ($line -like '*User sends a create gist request*')
				{
					$GherkinUseCase.ActionType = "Create Gist"
					$GherkinUseCase.Method = "POST"
				}
				if ($line -like '*User sends a read gist request*')
				{
					$GherkinUseCase.ActionType = "Read Gist"	
					$GherkinUseCase.Method = "GET"
				}				
				if ($line -like '*User sends a read starred gist request*')
				{
					$GherkinUseCase.ActionType = "Read Starred Gist"
					$GherkinUseCase.Method = "GET"
				}		
				if ($line -like '*User sends an update (star) request*')
				{
					$GherkinUseCase.ActionType = "Update (Star) Gist"
					$GherkinUseCase.Method = "PUT"
				}
				if ($line -like '*User sends isStarred gist request*')
				{
					$GherkinUseCase.ActionType = "IsStarred Gist"
					$GherkinUseCase.Method = "GET"
				}
				if ($line -like '*User sends an update (unstar) request*')
				{
					$GherkinUseCase.ActionType = "Update (Unstar) Gist"
					$GherkinUseCase.Method = "DELETE"
				}
				if ($line -like '*User sends a delete gist request*')
				{
					$GherkinUseCase.ActionType = "Delete Gist"
					$GherkinUseCase.Method = "DELETE"
				}
				WriteLog "Property ActionType is set to $($GherkinUseCase.ActionType)"
				WriteLog "Property Method is set to $($GherkinUseCase.Method)"
			}
			
			if ($line -like '*Then*')
			{
				$CurrentSection = "Then"
				if ($line -like '*Response code*')
				{
					$Filter = $line.Split("(")
					$ResultCode = $Filter[1].Replace(")",$null)			
					$GherkinUseCase.ExpectedResponseCode = $ResultCode
					WriteLog "Property ExpectedResponseCode is set to $($GherkinUseCase.ExpectedResponseCode)"
				}			
			}
			
			if ($line -like '*And*')
			{
				if ($CurrentSection -eq "Then")
				{
					if ($line -like '*Response time is acceptable*')
					{
						$Filter = $line.Split("(")
						$ResponseTime = $Filter[1].Replace(")",$null)
						$ResponseTime = ($ResponseTime.Replace("s",$null)) -as [int]
						$GherkinUseCase.ExpectedResponseTime = $ResponseTime * 1000
						WriteLog "Property ExpectedResponseTime is set to $($GherkinUseCase.ExpectedResponseTime)"
					}
					
					if ($line -like '*Content-Type header is set*')
					{
						$GherkinUseCase.ContentTypeHeader = "Set"
						WriteLog "Property ContentTypeHeader is set to $($GherkinUseCase.ContentTypeHeader)"
					}
				}
			}
		}
		$UseCaseCollection += ProcessUseCase -GherkinUseCase $GherkinUseCase

		# Generate Header and Footer
		$PostmanPreJSON = CreateJsonObject -postmanId "1aa9caa0-6269-4c97-9dbd-0a98ee2afb4f" -name $File.BaseName -UseCaseCollection $UseCaseCollection
		$PostmanJSON = ConvertTo-Json($PostmanPreJSON) -Depth 10
		$PostmanFileName = $File.FullName -replace "\.gherkin", ".json"
		Add-Content -Path $PostmanFileName -Value $PostmanJSON
		
	}
	StopExecution
}
$AuthToken = $args[1]
if ($AuthToken -eq $null) { AskToken }
main
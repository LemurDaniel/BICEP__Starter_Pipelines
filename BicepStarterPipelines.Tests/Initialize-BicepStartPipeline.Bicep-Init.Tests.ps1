BeforeAll {
    Remove-Module "$PSScriptRoot\..\BicepStarterPipelines" -Force -ErrorAction SilentlyContinue
    Import-Module "$PSScriptRoot\..\BicepStarterPipelines" -Force
}

BeforeDiscovery {

    $methods = 'Normal Deployment', 'Deployment Stack'
    $scopes = 'Resource Group', 'Subscription'
    $scripts = 'PowerShell' #, 'Azure CLI'
    $pipelines = 'Github', 'Azure DevOps'

    $cartesianProduct = $methods.ForEach{ $method = $_
        $scopes.ForEach{ $scope = $_
            $scripts.ForEach{ $script = $_
                $pipelines.ForEach{
                    return @{
                        Method   = $method
                        Scope    = $scope
                        Script   = $script
                        Pipeline = $_
                    }
                }
            }
        }
    } 
}

Describe 'Initialize-BicepStartPipeline' {

    AfterAll {
        $Global:BicepStarterPipelinesNonInteractive = $null
        Remove-Item -Path "$PSScriptRoot/pester" -Force -Confirm:$false -Recurse -ErrorAction SilentlyContinue
    }
    
    #It 'Interactive Mode' -Skip:$Global:BicepStarterPipelinesNonInteractive {
    #    $destination = "$PSScriptRoot/pester/interactive"
    #
    #    bicep-init $destination
    #
    #    Test-Path -Path $destination | Should -Be $true
    #}

    Context 'Non-Interactive Tests | <Method> | <Scope> | <Script> | <Pipeline>' -ForEach $cartesianProduct {

        BeforeAll {

            $destination = "$PSScriptRoot/pester/automated/$(Get-Random)"
            $splat = @{
                Template = 'deployment'
                Target   = $destination
                Method   = $method
                Scope    = $scope
                Pipeline = $pipeline
            }

            bicep-init @splat
        }

        It 'Should create destination if not exists' {
            Test-Path -Path $destination | Should -BeTrue
        }

        It 'Should use <pipeline> pipelines' {

            $githubMatch = $pipeline -IEQ 'Github'
            $azdoMatch = $pipeline -IEQ 'Azure DevOps'

            Test-Path -Path "$destination/.github" | Should -Be $githubMatch
            Test-Path -Path "$destination/.github/workflows" | Should -Be $githubMatch
 
            Test-Path -Path "$destination/.github/workflows/deploy.infrastructure.dev.yaml" | Should -Be $githubMatch
            Test-Path -Path "$destination/.github/workflows/deploy.infrastructure.test.yaml" | Should -Be $githubMatch
            Test-Path -Path "$destination/.github/workflows/deploy.infrastructure.prod.yaml" | Should -Be $githubMatch
            Test-Path -Path "$destination/.github/workflows/tmpl.deploy.infrastructure.yaml" | Should -Be $githubMatch
 

            Test-Path -Path "$destination/.devops" | Should -Be $azdoMatch
            Test-Path -Path "$destination/.devops/stage" | Should -Be $azdoMatch
            Test-Path -Path "$destination/.devops/deploy.infrastructure.yaml" | Should -Be $azdoMatch
            Test-Path -Path "$destination/.devops/stage/tmpl.bicep.infra.variables.yaml" | Should -Be $azdoMatch
            Test-Path -Path "$destination/.devops/stage/tmpl.bicep.infra.deploy.yaml" | Should -Be $azdoMatch
        }

        It 'Should use <method>' {
            $shouldNotMatch = $method -IEQ 'Normal Deployment'

            if ($pipeline -IEQ 'Github') {
                Get-ChildItem -Path "$destination/.github/workflows" 
                | Where-Object -Property Name -LIKE 'tmpl.*.yml'
                | ForEach-Object {
                    $_ | Should -FileContentMatch "`${{ inputs.deny_settings_mode }}" -Not:$shouldNotMatch
                    $_ | Should -FileContentMatch "`${{ inputs.action_on_unmanage }}" -Not:$shouldNotMatch
                }
            }
            else {
                Get-ChildItem -Path "$destination/.devops/stage"
                | Where-Object -Property Name -LIKE 'tmpl.*.yml'
                | ForEach-Object {
                    $_ | Should -FileContentMatch "`${{ parameters.denySettingsMode }}" -Not:$shouldNotMatch
                    $_ | Should -FileContentMatch "`${{ parameters.actionOnUnmanage }}" -Not:$shouldNotMatch
                }
            }
        }

        It 'Should use <script>' {
            # Test-Path -Path "$destination/deploy.ps1" | Should -BeFalse # TODO

            if ($pipeline -IEQ 'Github') {
                $expectedScript = $script -IEQ 'PowerShell' ? 'azure/cli@v2' : 'azure/powershell@v2'
                $notExpectedScript = $script -IEQ 'PowerShell' ? 'azure/powershell@v2' : 'azure/cli@v2'

                Get-ChildItem -Path "$destination/.github/workflows" 
                | Where-Object -Property Name -LIKE 'tmpl.*.yml'
                | ForEach-Object {
                    $_ | Should -FileContentMatch "uses: $expectedScript"
                    $_ | Should -Not -FileContentMatch "uses: $notExpectedScript"
                }
            }
            else {
                $expectedScript = $script -IEQ 'PowerShell' ? 'bash' : 'pscore'
                $notExpectedScript = $script -IEQ 'PowerShell' ? 'pscore' : 'bash'

                Get-ChildItem -Path "$destination/.devops/stage"
                | Where-Object -Property Name -LIKE 'tmpl.*.yml'
                | ForEach-Object {
                    $_ | Should -FileContentMatch "scriptType: expectedScript"
                    $_ | Should -Not -FileContentMatch "scriptType: notExpectedScript"
                }
            }
        }

        It 'Should set deployment scope to <scope>' {
            $expectedScope = $scope -IEQ 'Subscription' ? 'subscription' : 'resourceGroup'
            $notExpectedScope = $scope -IEQ 'Subscription' ? 'resourceGroup' : 'subscription'

            Get-Item -Path "$destination/main.bicep" | Should -FileContentMatch "targetScope = '$expectedScope'"

            if ($pipeline -IEQ 'Github') {
                Get-ChildItem -Path "$destination/.github/workflows" 
                | Where-Object -Property Name -LIKE 'deploy.*.yml'
                | ForEach-Object {
                    $_ | Should -FileContentMatch  "scope: $expectedScope"
                    $_ | Should -Not -FileContentMatch  "scope: $notExpectedScope"
                }
            }
            else {
                Get-ChildItem -Path "$destination/.devops"
                | Where-Object -Property Name -LIKE 'deploy.*.yml'
                | ForEach-Object {
                    $_ | Should -FileContentMatch  "value: $expectedScope # subscription | resourceGroup" 
                    $_ | Should -Not -FileContentMatch  "value: $notExpectedScope # subscription | resourceGroup"
                }
            }
        }
    }
    
}
BeforeAll {
    Remove-Module "$PSScriptRoot\..\BicepStarterPipelines" -Force -ErrorAction SilentlyContinue
    Import-Module "$PSScriptRoot\..\BicepStarterPipelines" -Force
}

Describe 'Initialize-BicepStartPipeline' {

    Context 'Default Path' {

        It 'Files should be created' {
            $destination = './pester'

            bicep-init $destination

            Test-Path -Path $destination | Should -Be $true
        }

    }
    
}
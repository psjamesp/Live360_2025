# JEA DEMO Implementation Guide

This package contains all the necessary files to implement and demonstrate Just Enough Administration (JEA) in your PowerShell environment.

## 📁 Package Contents

### Configuration Files
- **BasicOperator.psrc** - Role capability file for basic operations (restart services, view processes, etc.)
- **AdvancedOperator.psrc** - Role capability file for advanced operations (install features, restart computers, etc.)
- **DEMO.pssc** - Session configuration file that defines the DEMO endpoint

### Scripts
- **Deploy-JEAEndpoint.ps1** - Automated deployment script for setting up the DEMO endpoint
- **Test-JEAEndpoint.ps1** - Comprehensive testing script to validate JEA functionality

### Documentation
- **JEA-Implementation-Slides.md** - Complete presentation slides in Markdown format

## 🚀 Quick Start

### Prerequisites
- Windows Server 2016 or later / Windows 10 or later
- PowerShell 5.1 or later
- Administrator privileges
- WinRM service enabled

### Step 1: Prepare Your Environment
```powershell
# Verify PowerShell version
$PSVersionTable.PSVersion

# Ensure WinRM is running
Get-Service WinRM
```

### Step 2: Deploy the DEMO Endpoint
```powershell
# Run the deployment script as Administrator
.\Deploy-JEAEndpoint.ps1
```

This script will:
1. Create the required directory structure
2. Copy role capability files to the correct location
3. Copy the session configuration file
4. Register the DEMO endpoint
5. Restart the WinRM service
6. Verify the deployment

### Step 3: Test the Endpoint
```powershell
# Run the testing script
.\Test-JEAEndpoint.ps1
```

### Step 4: Connect Interactively
```powershell
# Connect to the JEA endpoint
Enter-PSSession -ComputerName localhost -ConfigurationName DEMO

# List available commands
Get-Command

# Try some commands
Get-Service
Get-Process

# Exit the session
Exit-PSSession
```

## 📋 Role Definitions

### BasicOperator Role
**Intended for:** Help desk, Tier 1 support

**Capabilities:**
- View services and processes
- Restart specific services (Spooler, W3SVC, WinRM)
- View event logs
- View Windows features
- Run basic network commands (whoami, ipconfig)
- Use custom Get-ServiceStatus function

**Restrictions:**
- Cannot stop arbitrary services (only Spooler, W3SVC, WinRM)
- Cannot modify system files
- Cannot install software
- Limited to NoLanguage mode

### AdvancedOperator Role
**Intended for:** Server administrators, Tier 2 support

**Capabilities:**
- All BasicOperator capabilities, plus:
- Stop processes
- Modify service startup type
- Restart computers
- Install Windows features
- Advanced network diagnostics (ping, netstat)
- Use custom system information functions

**Restrictions:**
- Still operates in NoLanguage mode
- Cannot run arbitrary scripts
- Limited external commands

## 🔧 Customization

### Adding a New Role
1. Create a new .psrc file in the RoleCapabilities folder
2. Define VisibleCmdlets, VisibleFunctions, etc.
3. Update the DEMO.pssc RoleDefinitions to map users/groups to the new role
4. Re-register the endpoint: `Register-PSSessionConfiguration -Path DEMO.pssc -Name DEMO -Force`

### Modifying User Assignments
Edit the RoleDefinitions section in DEMO.pssc:

```powershell
RoleDefinitions = @{
    'DOMAIN\YourGroup' = @{
        RoleCapabilities = 'BasicOperator'
    }
}
```

### Adding Custom Functions
In your .psrc file, add to FunctionDefinitions:

```powershell
FunctionDefinitions = @(
    @{
        Name = 'Get-CustomInfo'
        ScriptBlock = {
            # Your custom code here
        }
    }
)
```

## 🔐 Security Considerations

### Virtual Accounts
By default, this configuration uses Virtual Accounts (`RunAsVirtualAccount = $true`). This means:
- Commands run with elevated privileges
- Each session gets a unique temporary account
- The account is automatically cleaned up after the session ends
- Users never have access to the actual credentials

### Group Managed Service Accounts (gMSA)
For multi-server scenarios or domain resource access, consider using gMSA:

```powershell
# In your .pssc file
RunAsVirtualAccount = $false
GroupManagedServiceAccount = 'DOMAIN\JEA-gMSA$'
```

### Transcript Auditing
All JEA sessions are automatically transcribed to:
`C:\ProgramData\JEAConfiguration\Transcripts`

**Important:** Ensure this directory has proper ACLs to prevent tampering:
```powershell
# Administrators: Full Control
# SYSTEM: Full Control
# JEA Users: No access
icacls C:\ProgramData\JEAConfiguration\Transcripts /inheritance:r
icacls C:\ProgramData\JEAConfiguration\Transcripts /grant "Administrators:(OI)(CI)F"
icacls C:\ProgramData\JEAConfiguration\Transcripts /grant "SYSTEM:(OI)(CI)F"
```

## 🔍 Troubleshooting

### "The term 'xxx' is not recognized"
**Cause:** The command is not in the VisibleCmdlets list
**Solution:** Add the command to the appropriate .psrc file

### "Cannot validate argument on parameter 'Name'"
**Cause:** Parameter value not in ValidateSet
**Solution:** Either adjust the ValidateSet in the .psrc file or use an allowed value

### "Access is denied"
**Cause:** User is not in a mapped role
**Solution:** Add the user's group to RoleDefinitions in DEMO.pssc

### Endpoint doesn't appear
**Cause:** Registration failed or WinRM not restarted
**Solution:** 
```powershell
# Check registration
Get-PSSessionConfiguration -Name DEMO

# Re-register if needed
Register-PSSessionConfiguration -Path DEMO.pssc -Name DEMO -Force

# Restart WinRM
Restart-Service WinRM
```

### Transcripts not created
**Cause:** Directory doesn't exist or insufficient permissions
**Solution:**
```powershell
New-Item -Path "C:\ProgramData\JEAConfiguration\Transcripts" -ItemType Directory -Force
```

## 📊 Monitoring & Auditing

### View Active Sessions
```powershell
Get-PSSession -ComputerName localhost -ConfigurationName DEMO
```

### Check Recent Transcripts
```powershell
Get-ChildItem "C:\ProgramData\JEAConfiguration\Transcripts" -Recurse | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 10
```

### Monitor Windows Event Logs
```powershell
Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -MaxEvents 50 | 
    Where-Object {$_.Message -like "*DEMO*"}
```

## 🎯 Use Cases

### Help Desk Scenario
**Task:** Reset user passwords without full AD admin rights

**Implementation:**
```powershell
VisibleCmdlets = @(
    'Get-ADUser',
    @{
        Name = 'Set-ADAccountPassword'
        Parameters = @{
            Name = 'Identity'
            ValidatePattern = '^[a-zA-Z0-9]+$'
        }
    }
)
```

### Web Server Management
**Task:** Manage IIS without full admin access

**Implementation:**
```powershell
VisibleCmdlets = @(
    'Get-Website',
    'Start-Website',
    'Stop-Website',
    'Restart-WebAppPool'
)
ModulesToImport = 'WebAdministration'
```

### Database Administration
**Task:** Backup SQL databases without sysadmin rights

**Implementation:**
```powershell
VisibleCmdlets = @(
    'Backup-SqlDatabase',
    'Restore-SqlDatabase',
    'Get-SqlDatabase'
)
ModulesToImport = 'SqlServer'
```

## 📚 Best Practices

1. **Start Small:** Begin with one role and one group, then expand
2. **Test Thoroughly:** Always test with actual user accounts before production
3. **Document Everything:** Maintain clear documentation of roles and assignments
4. **Review Regularly:** Audit role assignments and capabilities quarterly
5. **Use ValidateSet:** Constrain parameters wherever possible
6. **Enable Transcription:** Always log sessions for audit purposes
7. **Use AD Groups:** Never assign roles to individual users
8. **Version Control:** Store .psrc and .pssc files in source control

## 🔄 Maintenance

### Updating Roles
1. Modify the .psrc file
2. Test in a dev environment
3. Re-register the endpoint
4. Communicate changes to users

### Removing the Endpoint
```powershell
Unregister-PSSessionConfiguration -Name DEMO -Force
Remove-Item -Path "$env:ProgramFiles\WindowsPowerShell\Modules\JEA_DEMO" -Recurse -Force
```

### Backing Up Configuration
```powershell
# Export configuration
$backupPath = "C:\JEA-Backup-$(Get-Date -Format 'yyyyMMdd')"
New-Item -Path $backupPath -ItemType Directory -Force
Copy-Item -Path "$env:ProgramFiles\WindowsPowerShell\Modules\JEA_DEMO\*" -Destination $backupPath -Recurse
```

## 📖 Additional Resources

### Microsoft Documentation
- [JEA Overview](https://docs.microsoft.com/en-us/powershell/scripting/learn/remoting/jea/overview)
- [Role Capabilities](https://docs.microsoft.com/en-us/powershell/scripting/learn/remoting/jea/role-capabilities)
- [Session Configurations](https://docs.microsoft.com/en-us/powershell/scripting/learn/remoting/jea/session-configurations)

### PowerShell Gallery
- Search for "JEA" modules and examples
- Community-contributed role capabilities

### Community
- PowerShell.org forums
- Reddit r/PowerShell
- PowerShell Discord server

## 🆘 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review PowerShell event logs
3. Examine transcripts for error details
4. Consult Microsoft documentation

## 📝 Version History

**Version 1.0** (November 2025)
- Initial DEMO implementation
- BasicOperator and AdvancedOperator roles
- Automated deployment scripts
- Comprehensive testing suite
- Full presentation materials

## ⚖️ License

This implementation guide and associated files are provided as-is for educational and operational purposes. Modify as needed for your environment.

## ✅ Checklist for Production Deployment

- [ ] Test in dev/lab environment
- [ ] Document role assignments
- [ ] Create AD groups for role mapping
- [ ] Set up transcript directory with proper ACLs
- [ ] Configure log aggregation/monitoring
- [ ] Train users on JEA access
- [ ] Create runbooks for common tasks
- [ ] Establish change management process
- [ ] Schedule regular audits
- [ ] Plan backup/recovery procedures

---

**Ready to implement JEA? Start with the deployment script and customize based on your needs!**

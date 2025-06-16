secedit /export /cfg current_policy.cfg
Get-Content current_policy.cfg | Select-String "MinimumPasswordLength|PasswordComplexity"
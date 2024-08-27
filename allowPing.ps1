# Check and add rule for ICMPv4 if it doesn't exist
$ruleNameICMPv4 = "Allow ICMPv4-In"
if (-Not (Get-NetFirewallRule -DisplayName $ruleNameICMPv4 -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName $ruleNameICMPv4 -Protocol ICMPv4 -IcmpType 8 -Enabled True -Profile Any -Action Allow -Direction Inbound
    Write-Host "Rule for ICMPv4 added."
} else {
    Write-Host "Rule for ICMPv4 already exists."
}

# Check and add rule for ICMPv6 if it doesn't exist
$ruleNameICMPv6 = "Allow ICMPv6-In"
if (-Not (Get-NetFirewallRule -DisplayName $ruleNameICMPv6 -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName $ruleNameICMPv6 -Protocol ICMPv6 -IcmpType 128 -Enabled True -Profile Any -Action Allow -Direction Inbound
    Write-Host "Rule for ICMPv6 added."
} else {
    Write-Host "Rule for ICMPv6 already exists."
}

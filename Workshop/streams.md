Success Stream: This is the default stream for normal, successful results. Use the Write-Output cmdlet to write objects to this stream. It is connected to the stdout stream for native applications.

Error Stream: This stream is used for error results. Use the Write-Error cmdlet to write to this stream. It is connected to the stderr stream for native applications. Errors written to this stream are also added to the $Error automatic variable.

Warning Stream: This stream is intended for less severe error conditions. Use the Write-Warning cmdlet to write to this stream. Warnings do not terminate execution and are not added to the $Error variable.

Verbose Stream: This stream is used for messages that help troubleshoot commands. Use the Write-Verbose cmdlet to write to this stream. Verbose messages are output only when the -Verbose common parameter is used.

Debug Stream: This stream is used for messages that help understand why code is failing. Use the Write-Debug cmdlet to write to this stream. Debug messages are output only when the -Debug common parameter is used.

Information Stream: This stream provides messages that help understand what a script is doing. Use the Write-Information cmdlet to write to this stream. Write-Host also writes to the Information stream but additionally writes to the host console unless redirected.
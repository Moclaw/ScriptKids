param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureName,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("Query", "Queries", "Command")]
    [string]$Type,
    
    [Parameter(Mandatory=$true)]
    [string]$OperationName
)

$rootPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$featuresPath = Join-Path -Path $rootPath -ChildPath "src\Sample.Application\Features"
$endpointsPath = Join-Path -Path $rootPath -ChildPath "src\Sample.API\Endpoints"

function Create-Feature-Files {
    param(
        [string]$FeatureName,
        [string]$Type,
        [string]$OperationName
    )
    
    # Create feature directory structure
    $featurePath = Join-Path -Path $featuresPath -ChildPath $FeatureName
    # Both Query and Queries should go in a directory called "Queries"
    $directoryType = if ($Type -eq "Command") { "Commands" } else { "Queries" }
    $typePath = Join-Path -Path $featurePath -ChildPath $directoryType
    $operationPath = Join-Path -Path $typePath -ChildPath $OperationName
    
    if (!(Test-Path -Path $featurePath)) {
        New-Item -Path $featurePath -ItemType Directory | Out-Null
    }
    
    if (!(Test-Path -Path $typePath)) {
        New-Item -Path $typePath -ItemType Directory | Out-Null
    }
    
    if (!(Test-Path -Path $operationPath)) {
        New-Item -Path $operationPath -ItemType Directory | Out-Null
    }
      # Create Request file
    $requestFilePath = Join-Path -Path $operationPath -ChildPath "$OperationName.Request.cs"
    # Use the correct namespace based on the directory structure
    $requestContent = @"
namespace Sample.Application.Features.$FeatureName.$directoryType.$OperationName
{
    public class ${OperationName}Request : I$(if ($Type -eq "Command") { "Command" } else { "Query" })$(if ($Type -eq "Queries") { "Collection" })Request<${OperationName}Response>
    {
        public string? Search { get; set; }
        public int PageIndex { get; set; }
        public int PageSize { get; set; }
        public string OrderBy { get; set; } = "";
        public bool IsAscending { get; set; }
    }
}
"@
    Set-Content -Path $requestFilePath -Value $requestContent
    Write-Host "Created $requestFilePath"
      # Create Response file
    $responseFilePath = Join-Path -Path $operationPath -ChildPath "$OperationName.Response.cs"
    $responseContent = @"
namespace Sample.Application.Features.$FeatureName.$directoryType.$OperationName
{
    public class ${OperationName}Response
    {
    }
}
"@
    Set-Content -Path $responseFilePath -Value $responseContent
    Write-Host "Created $responseFilePath"
      # Create Handler file
    $handlerFilePath = Join-Path -Path $operationPath -ChildPath "$OperationName.Handler.cs"
    $handlerContent = @"
using Sample.Domain.Entities;

namespace Sample.Application.Features.$FeatureName.$directoryType.$OperationName
{
    public class ${OperationName}Handler
        (
            IQueryRepository<${FeatureName}Item, int> repository
        )
        : I$(if ($Type -eq "Command") { "Command" } else { "Query" })$(if ($Type -eq "Queries") { "Collection" })Handler<${OperationName}Request, ${OperationName}Response>
    {
        public async Task<Response<${OperationName}Response>> Handle(${OperationName}Request request, CancellationToken cancellationToken)
        {
            // Implementation goes here
            
            return new Response<${OperationName}Response>(IsSuccess: true, 200, "", Data: new ${OperationName}Response());
        }
    }
}
"@
    Set-Content -Path $handlerFilePath -Value $handlerContent
    Write-Host "Created $handlerFilePath"    # Create Endpoint structure
    $endpointFeaturePath = Join-Path -Path $endpointsPath -ChildPath $FeatureName
    # Both Query and Queries should go in a directory called "Queries" for endpoints as well
    $endpointDirectoryType = if ($Type -eq "Command") { "Commands" } else { "Queries" }
    $endpointTypePath = Join-Path -Path $endpointFeaturePath -ChildPath $endpointDirectoryType
    
    if (!(Test-Path -Path $endpointFeaturePath)) {
        New-Item -Path $endpointFeaturePath -ItemType Directory | Out-Null
    }
    
    if (!(Test-Path -Path $endpointTypePath)) {
        New-Item -Path $endpointTypePath -ItemType Directory | Out-Null
    }
      # Create Endpoint file
    $endpointFilePath = Join-Path -Path $endpointTypePath -ChildPath "$OperationName.Endpoint.cs"
    $httpMethod = if ($Type -eq "Command") { "Post" } else { "Get" }
    
    $endpointContent = @"
using Sample.Application.Features.$FeatureName.$directoryType.$OperationName;
using MediatR;
using MinimalAPI.Attributes;
using MinimalAPI.Endpoints;
using Shared.Responses;

namespace Sample.API.Endpoints.$FeatureName.$endpointDirectoryType
{
    [Route("$(${FeatureName}.ToLower())")]
    public class ${OperationName}Endpoint(IMediator mediator) : SingleEndpointBase<${OperationName}Request, ${OperationName}Response>(mediator)
    {
        [Http$httpMethod]
        public async override Task<Response<${OperationName}Response>> HandleAsync(${OperationName}Request req, CancellationToken ct)
        {
            return await _mediator.Send(req, ct);
        }
    }
}
"@
    Set-Content -Path $endpointFilePath -Value $endpointContent
    Write-Host "Created $endpointFilePath"
}

# Execute function
Create-Feature-Files -FeatureName $FeatureName -Type $Type -OperationName $OperationName

Write-Host "Feature generation completed successfully!"

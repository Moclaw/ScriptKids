#!/usr/bin/env bash
# filepath: /Users/lammoc/Project/ScriptKids/src/CleanArchitecture/templates/feature.sh

# This script creates the necessary files for a new feature in a Clean Architecture solution
# Usage: ./feature.sh <FeatureName> <Type> <OperationName>
# Type can be: Query, Queries, or Command

# Check for required arguments
if [ $# -lt 3 ]; then
  echo "❌ Error: Missing required arguments!"
  echo "👉 Usage: ./feature.sh <FeatureName> <Type> <OperationName>"
  echo "   Type can be: Query, Queries, or Command"
  exit 1
fi

FEATURE_NAME=$1
TYPE=$2
OPERATION_NAME=$3

# Validate TYPE argument
if [[ "$TYPE" != "Query" && "$TYPE" != "Queries" && "$TYPE" != "Command" ]]; then
  echo "❌ Error: Type must be one of: Query, Queries, Command"
  exit 1
fi

# Set root path and paths for features and endpoints
ROOT_PATH=$(pwd)
FEATURES_PATH="$ROOT_PATH/src/Sample.Application/Features"
ENDPOINTS_PATH="$ROOT_PATH/src/Sample.API/Endpoints"

# Create feature directory structure
echo "🏗️ Creating feature directory structure for $FEATURE_NAME..."

# Both Query and Queries should go in a directory called "Queries"
if [[ "$TYPE" == "Command" ]]; then
  DIRECTORY_TYPE="Commands"
else
  DIRECTORY_TYPE="Queries"
fi

FEATURE_PATH="$FEATURES_PATH/$FEATURE_NAME"
TYPE_PATH="$FEATURE_PATH/$DIRECTORY_TYPE"
OPERATION_PATH="$TYPE_PATH/$OPERATION_NAME"

mkdir -p "$OPERATION_PATH"

# Create Request file
echo "📝 Creating Request file..."
REQUEST_FILE_PATH="$OPERATION_PATH/$OPERATION_NAME.Request.cs"

# Use the correct interface based on the type
if [[ "$TYPE" == "Command" ]]; then
  INTERFACE="ICommandRequest"
elif [[ "$TYPE" == "Queries" ]]; then
  INTERFACE="IQueryCollectionRequest"
else
  INTERFACE="IQueryRequest"
fi

cat > "$REQUEST_FILE_PATH" << EOL
namespace Sample.Application.Features.$FEATURE_NAME.$DIRECTORY_TYPE.$OPERATION_NAME
{
    public class ${OPERATION_NAME}Request : $INTERFACE<${OPERATION_NAME}Response>
    {
        public string? Search { get; set; }
        public int PageIndex { get; set; }
        public int PageSize { get; set; }
        public string OrderBy { get; set; } = "";
        public bool IsAscending { get; set; }
    }
}
EOL
echo "✅ Created $REQUEST_FILE_PATH"

# Create Response file
echo "📝 Creating Response file..."
RESPONSE_FILE_PATH="$OPERATION_PATH/$OPERATION_NAME.Response.cs"

cat > "$RESPONSE_FILE_PATH" << EOL
namespace Sample.Application.Features.$FEATURE_NAME.$DIRECTORY_TYPE.$OPERATION_NAME
{
    public class ${OPERATION_NAME}Response
    {
    }
}
EOL
echo "✅ Created $RESPONSE_FILE_PATH"

# Create Handler file
echo "📝 Creating Handler file..."
HANDLER_FILE_PATH="$OPERATION_PATH/$OPERATION_NAME.Handler.cs"

# Use the correct interface based on the type
if [[ "$TYPE" == "Command" ]]; then
  HANDLER_INTERFACE="ICommandHandler"
elif [[ "$TYPE" == "Queries" ]]; then
  HANDLER_INTERFACE="IQueryCollectionHandler"
else
  HANDLER_INTERFACE="IQueryHandler"
fi

cat > "$HANDLER_FILE_PATH" << EOL
using Sample.Domain.Entities;

namespace Sample.Application.Features.$FEATURE_NAME.$DIRECTORY_TYPE.$OPERATION_NAME
{
    public class ${OPERATION_NAME}Handler
        (
            IQueryRepository<${FEATURE_NAME}Item, int> repository
        )
        : $HANDLER_INTERFACE<${OPERATION_NAME}Request, ${OPERATION_NAME}Response>
    {
        public async Task<Response<${OPERATION_NAME}Response>> Handle(${OPERATION_NAME}Request request, CancellationToken cancellationToken)
        {
            // Implementation goes here
            
            return new Response<${OPERATION_NAME}Response>(IsSuccess: true, 200, "", Data: new ${OPERATION_NAME}Response());
        }
    }
}
EOL
echo "✅ Created $HANDLER_FILE_PATH"

# Create Endpoint structure
echo "🏗️ Creating endpoint structure..."
ENDPOINT_FEATURE_PATH="$ENDPOINTS_PATH/$FEATURE_NAME"
# Both Query and Queries should go in a directory called "Queries" for endpoints as well
if [[ "$TYPE" == "Command" ]]; then
  ENDPOINT_DIRECTORY_TYPE="Commands"
else
  ENDPOINT_DIRECTORY_TYPE="Queries"
fi
ENDPOINT_TYPE_PATH="$ENDPOINT_FEATURE_PATH/$ENDPOINT_DIRECTORY_TYPE"

mkdir -p "$ENDPOINT_TYPE_PATH"

# Create Endpoint file
echo "📝 Creating Endpoint file..."
ENDPOINT_FILE_PATH="$ENDPOINT_TYPE_PATH/$OPERATION_NAME.Endpoint.cs"

# Set HTTP method based on type
if [[ "$TYPE" == "Command" ]]; then
  HTTP_METHOD="Post"
else
  HTTP_METHOD="Get"
fi

cat > "$ENDPOINT_FILE_PATH" << EOL
using Sample.Application.Features.$FEATURE_NAME.$DIRECTORY_TYPE.$OPERATION_NAME;
using MediatR;
using MinimalAPI.Attributes;
using MinimalAPI.Endpoints;
using Shared.Responses;

namespace Sample.API.Endpoints.$FEATURE_NAME.$ENDPOINT_DIRECTORY_TYPE
{
    [Route("$(echo $FEATURE_NAME | tr '[:upper:]' '[:lower:]')")]
    public class ${OPERATION_NAME}Endpoint(IMediator mediator) : SingleEndpointBase<${OPERATION_NAME}Request, ${OPERATION_NAME}Response>(mediator)
    {
        [Http$HTTP_METHOD]
        public async override Task<Response<${OPERATION_NAME}Response>> HandleAsync(${OPERATION_NAME}Request req, CancellationToken ct)
        {
            return await _mediator.Send(req, ct);
        }
    }
}
EOL
echo "✅ Created $ENDPOINT_FILE_PATH"

echo "✨ Feature generation completed successfully!"

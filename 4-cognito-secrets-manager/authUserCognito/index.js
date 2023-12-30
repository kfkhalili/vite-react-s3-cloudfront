const { CognitoIdentityProviderClient, InitiateAuthCommand } = require("@aws-sdk/client-cognito-identity-provider");

const client = new CognitoIdentityProviderClient({ region: process.env.AWS_REGION }); // Set this in your Lambda environment variables

exports.handler = async (event) => {
    try {
        const { email, password } = event;
        const authParams = {
            ClientId: process.env.COGNITO_CLIENT_ID, // Set this in your Lambda environment variables
            AuthFlow: "USER_PASSWORD_AUTH",
            AuthParameters: {
                USERNAME: email,
                PASSWORD: password
            }
        };

        const authCommand = new InitiateAuthCommand(authParams);
        const response = await client.send(authCommand);

        return { 
            statusCode: 200,
            body: JSON.stringify({ message: "Authentication successful", token: response.AuthenticationResult.IdToken })
        };
    } catch (error) {
        console.error(error);
        return { 
            statusCode: 500,
            body: JSON.stringify({ message: error.message })
        };
    }
};

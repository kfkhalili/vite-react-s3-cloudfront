const { CognitoIdentityProviderClient, InitiateAuthCommand } = require("@aws-sdk/client-cognito-identity-provider");

const client = new CognitoIdentityProviderClient({ region: process.env.AWS_REGION });

exports.handler = async (event) => {
    try {
        const { identifier, password } = event;
        // Check if the identifier is in an email format
        const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(identifier);

        // Prepare the authentication parameters
        let authParams = {
            'PASSWORD': password
        };

        // Set USERNAME or email based on the identifier type
        authParams[isEmail ? 'email' : 'USERNAME'] = identifier;

        const params = {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: process.env.COGNITO_CLIENT_ID,
            AuthParameters: authParams,
        };

        const authCommand = new InitiateAuthCommand(params);
        const response = await client.send(authCommand);

        return { 
            statusCode: 200,
            body: JSON.stringify({
                success: true,
                message: "Authentication successful", 
                token: response.AuthenticationResult?.IdToken 
            })
        };
    } catch (error) {
        console.error(error);
        return { 
            statusCode: 500,
            body: JSON.stringify({ 
                success: false,
                message: error.message,
                token: null })
        };
    }
};

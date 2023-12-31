const { CognitoIdentityProviderClient, SignUpCommand, AdminGetUserCommand } = require("@aws-sdk/client-cognito-identity-provider");

const client = new CognitoIdentityProviderClient({ region: process.env.AWS_REGION });

exports.handler = async (event) => {
    try {
        const { username, email, password } = event;
        const signUpParams = {
            ClientId: process.env.COGNITO_CLIENT_ID, // Set this in your Lambda environment variables
            Username: username,
            Email: email,
            Password: password,
            UserAttributes: [
                { Name: "email", Value: email }
            ]
        };

        const signUpCommand = new SignUpCommand(signUpParams);
        await client.send(signUpCommand);

        return { 
            statusCode: 200,
            body: JSON.stringify({ 
                success: true,
                message: "User registered successfully",
            })
        };
    } catch (error) {
        console.error(error);
        return { 
            statusCode: 500,
            body: JSON.stringify({ 
                success: false,
                message: error.message,
            })
        };
    }
};

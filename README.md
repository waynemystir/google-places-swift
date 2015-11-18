This is a simple app that demostrates the use of the Google Places API

# Setup

1. Go to the [Google Developers Console](https://console.developers.google.com/)
2. Select a project or create a new one
3. Enable the Google Places API Web Service
4. Select the Enabled APIs link in the API section to see a list of all your enabled APIs. Make sure that the API is on the list of enabled APIs.
5. Add Credentials -> API Key -> iOS Key
6. Do not add anything for "Accepts requests from ... bundle identifiers"

Once you have the API key, add it to the project:

1. Open the project
2. Navigate to `LoadGoogleData.m`
3. Replace the value for GOOGLE_API_KEY with your API key

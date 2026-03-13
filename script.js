// Populate environment variables in the static page
const envVars = {
    appName: 'Service Binding Preview',
    environment: 'production',
    version: '1.0.0',
    port: '3000',
    apiKey: '***hidden***',
    databaseUrl: '***hidden***'
};

// Set values in the DOM
document.getElementById('app-name').textContent = envVars.appName;
document.getElementById('environment').textContent = envVars.environment;
document.getElementById('version').textContent = envVars.version;
document.getElementById('port').textContent = envVars.port;
document.getElementById('api-key').textContent = envVars.apiKey;
document.getElementById('database-url').textContent = envVars.databaseUrl;

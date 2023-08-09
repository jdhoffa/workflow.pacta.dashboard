# workflow.pacta.dashboard

This is a test repository who's purpose is to protoype viewing the [PACTA interactive report](https://platform.transitionmonitor.com) with sections in a tabular format.

# Spinning up the dashboard
To spin up this dashboard, you will need to have access to the (private) Azure Transitin Monitor container registry. 

To log-in, run:
``` bash
az acr login --name transitionmonitordockerregistry
```
Then, you can build and run the app by running:
``` bash
docker-compose up --build
```

To see the application, navigate to `localhost:3838` in a browser. 

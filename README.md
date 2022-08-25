## Azure Container Apps use cases covered in this tutorial
Complete [10 posts tutorial](https://bit.ly/ACATutorial) where we will build a tasks management application following the microservices architecture pattern [Live demo application](https://tasksmanager-frontend-webapp.agreeablestone-8c14c04c.eastus.azurecontainerapps.io/), this application will consist of 3 microservices and each one has certain capabilities to show how **Azure Container Apps and Dapr** can simplify the building of a microservice application. Below is the architecture diagram of the application we are going to build in this tutorial:
![Azure Container Apps Architecture for building Microservices using dapr-1](https://user-images.githubusercontent.com/3114431/186751157-c2857bf1-8db9-492b-92ce-6127209a6757.jpg)
Use cases which we will cover during this tutorial are:
- Web App front-end application that accepts requests from users to manage their tasks.
- Backend Web API which contains the business logic of tasks management service and data storage.
- An event-driven backend processor which is responsible to send emails to tasks owners based on messages coming from Azure Service Bus Topic
- Continuously running background processor to flag overdue tasks running continuously based on Cron timer configuration
- Use Azure Container Registry to build and host container images and deploy images from ACR to Azure Container Apps

## Dapr Integration with Azure Container Apps in this tutorial

Dapr provides a set of APIs that simplify the authoring of microservice applications, once Dapr is enabled in Azure Container Apps, it exposes its APIs via a sidecar (a process that runs together with each Azure Container App), The Dapr APIs/Building blocks used in this tutorial are:

- Service to service invocation: Web front-end app microservice invokes the backend API microservice using Dapr sidecar
- State management: Backend API stores data on Azure Cosmos DB and some email logs on Azure Table Storage using Dapr state management building blocks
- Pub/Sub: Backend API publishes messages to Azure Service Bus when a task is saved and the backend processor consumes those messages and sends an email using SendGrid
- Bindings: The backend processor is triggered based on an incoming event such as a Cron job

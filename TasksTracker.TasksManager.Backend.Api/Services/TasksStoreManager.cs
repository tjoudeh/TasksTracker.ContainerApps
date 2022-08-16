using System.Text.Json.Nodes;
using Dapr.Client;
using Microsoft.Azure.Cosmos;
using TasksTracker.TasksManager.Backend.Api.Models;

namespace TasksTracker.TasksManager.Backend.Api.Services
{
    public class TasksStoreManager : ITasksManager
    {
        private static string STORE_NAME = "statestore";
        private static string PUBSUB_NAME = "taskspubsub";
        private static string PUBSUB_SVCBUS_NAME = "dapr-pubsub-servicebus";
        private static string TASK_SAVED_TOPICNAME = "tasksavedtopic";
        private readonly DaprClient _daprClient;

        private readonly IConfiguration _config;

        public TasksStoreManager(DaprClient daprClient, IConfiguration config)
        {
            _daprClient = daprClient;
            _config = config;
        }
        public async Task<bool> CreateNewTask(string taskName, string createdBy, string assignedTo, DateTime dueDate)
        {
            var taskModel = new TaskModel()
            {
                TaskId = Guid.NewGuid(),
                TaskName = taskName,
                TaskCreatedBy = createdBy,
                TaskCreatedOn = DateTime.UtcNow,
                TaskDueDate = dueDate,
                TaskAssignedTo = assignedTo,
            };

            await _daprClient.SaveStateAsync<TaskModel>(STORE_NAME, taskModel.TaskId.ToString(), taskModel);

            await PublishTaskSavedEvent(taskModel);

            return true;
        }

        public async Task<bool> DeleteTask(Guid taskId)
        {
            await _daprClient.DeleteStateAsync(STORE_NAME, taskId.ToString());
            return true;
        }

        public async Task<TaskModel?> GetTaskById(Guid taskId)
        {
            var taskModel = await _daprClient.GetStateAsync<TaskModel>(STORE_NAME, taskId.ToString());

            return taskModel;
        }

        public async Task<List<TaskModel>> GetTasksByCreator(string createdBy)
        {
            //Currently, the query API for Cosmos DB is not working when deploying it to Azure Container Apps, this is an open
            //issue and prodcut team is wokring on it. Details of the issue is here: https://github.com/microsoft/azure-container-apps/issues/155
            //Due to this issue, we will query directly the cosmos db to list tasks per created by user.

            // var query = "{" +
            //        "\"filter\": {" +
            //            "\"EQ\": { \"taskCreatedBy\": \"" + createdBy + "\" }" +
            //        "}}";

            // var queryResponse = await _daprClient.QueryStateAsync<TaskModel>(STORE_NAME, query);

            // var tasksList = queryResponse.Results.Select(q => q.Data).OrderByDescending(o=>o.TaskCreatedOn);

            // return tasksList.ToList();

            //Workaround: Query cosmos DB directly
            var result = await QueryCosmosDb(createdBy);

            return result;

        }

        private async Task<List<TaskModel>> QueryCosmosDb(string createdBy)
        {
            var databaseName = "tasksmanagerdb";
            var containerName = "taskscollection";
            var account = "https://taskstracker-state-store.documents.azure.com:443/";
            var cosmosKey = _config.GetValue<string>("cosmosDb:key");

            var cosmosClient = new CosmosClient(account, cosmosKey);
            var container = cosmosClient.GetContainer(databaseName, containerName);

            var queryString = $"SELECT * FROM C['value'] as tasksList Where tasksList.taskCreatedBy = @taskCreatedBy";
            var queryDefinition = new QueryDefinition(queryString).WithParameter("@taskCreatedBy", createdBy);

            using FeedIterator<TaskModel> feed = container.GetItemQueryIterator<TaskModel>(queryDefinition: queryDefinition);

            var results = new List<TaskModel>();

            while (feed.HasMoreResults)
            {
                FeedResponse<TaskModel> response = await feed.ReadNextAsync();

                results.AddRange(response.OrderByDescending(o => o.TaskCreatedOn).ToList());

            }

            return results;
        }

        public async Task<bool> MarkTaskCompleted(Guid taskId)
        {
            var taskModel = await _daprClient.GetStateAsync<TaskModel>(STORE_NAME, taskId.ToString());

            if (taskModel != null)
            {
                taskModel.IsCompleted = true;
                await _daprClient.SaveStateAsync<TaskModel>(STORE_NAME, taskModel.TaskId.ToString(), taskModel);
                return true;
            }

            return false;
        }

        public async Task<bool> UpdateTask(Guid taskId, string taskName, string assignedTo, DateTime dueDate)
        {
            var taskModel = await _daprClient.GetStateAsync<TaskModel>(STORE_NAME, taskId.ToString());

            var currentAssignee = taskModel.TaskAssignedTo;

            if (taskModel != null)
            {
                taskModel.TaskName = taskName;
                taskModel.TaskAssignedTo = assignedTo;
                taskModel.TaskDueDate = dueDate;

                await _daprClient.SaveStateAsync<TaskModel>(STORE_NAME, taskModel.TaskId.ToString(), taskModel);

                if (!taskModel.TaskAssignedTo.Equals(currentAssignee, StringComparison.OrdinalIgnoreCase))
                {
                    await PublishTaskSavedEvent(taskModel);
                }

                return true;
            }

            return false;
        }

        private async Task PublishTaskSavedEvent(TaskModel taskModel)
        {

            await _daprClient.PublishEventAsync(PUBSUB_SVCBUS_NAME, TASK_SAVED_TOPICNAME, taskModel);
        }
    }
}

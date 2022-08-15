using System.Text.Json.Nodes;
using Dapr.Client;
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

        public TasksStoreManager(DaprClient daprClient)
        {
            _daprClient = daprClient;
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
            var query = "{" +
                   "\"filter\": {" +
                       "\"EQ\": { \"taskCreatedBy\": \"" + createdBy + "\" }" +
                   "}}";

            var queryResponse = await _daprClient.QueryStateAsync<TaskModel>(STORE_NAME, query);

            var tasksList = queryResponse.Results.Select(q => q.Data).OrderByDescending(o=>o.TaskCreatedOn);

            return tasksList.ToList();

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

            if (taskModel != null)
            {
                taskModel.TaskName = taskName;
                taskModel.TaskAssignedTo = assignedTo;
                taskModel.TaskDueDate = dueDate;

                await _daprClient.SaveStateAsync<TaskModel>(STORE_NAME, taskModel.TaskId.ToString(), taskModel);

                if (taskModel.TaskAssignedTo != assignedTo){
                    await PublishTaskSavedEvent(taskModel);
                }

                return true;
            }

            return false;
        }

        private async Task PublishTaskSavedEvent(TaskModel taskModel){
            
            await _daprClient.PublishEventAsync(PUBSUB_SVCBUS_NAME, TASK_SAVED_TOPICNAME, taskModel);
        }
    }
}

using TasksTracker.TasksManager.Backend.Api.Models;

namespace TasksTracker.TasksManager.Backend.Api.Services
{
    public interface ITasksManager
    {
        List<TaskModel> GetTasksByCreator(string createdBy);

        TaskModel? GetTaskById(Guid taskId);

        bool CreateNewTask(string taskName, string createdBy, string assignedTo, DateTime dueDate);

        bool UpdateTask(Guid taskId, string taskName, string assignedTo, DateTime dueDate);

        bool MarkTaskCompleted(Guid taskId);

        bool DeleteTask(Guid taskId);
    }
}

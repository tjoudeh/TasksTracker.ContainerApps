using TasksTracker.TasksManager.Backend.Api.Models;

namespace TasksTracker.TasksManager.Backend.Api.Services
{
    public class FakeTasksManager : ITasksManager
    {
        private List<TaskModel> _tasksList = new List<TaskModel>();
        Random rnd = new Random();

        private void GenerateRandomTasks()
        {
            for (int i = 0; i < 10; i++)
            {
                var task = new TaskModel()
                {
                    TaskId = Guid.NewGuid(),
                    TaskName = $"Task number: {i}",
                    TaskCreatedBy = "tjoudeh@bitoftech.net",
                    TaskCreatedOn = DateTime.UtcNow.AddMinutes(i),
                    TaskDueDate = DateTime.UtcNow.AddDays(i),
                    TaskAssignedTo = $"assignee{rnd.Next(50)}@mail.com;assignee{rnd.Next(50)}@mail.com;",
                };

                _tasksList.Add(task);
            }
        }

        public FakeTasksManager()
        {
            GenerateRandomTasks();
        }

        public bool CreateNewTask(string taskName, string createdBy, string assignedTo, DateTime dueDate)
        {
            var task = new TaskModel()
            {
                TaskId = Guid.NewGuid(),
                TaskName = taskName,
                TaskCreatedBy = createdBy,
                TaskCreatedOn = DateTime.UtcNow,
                TaskDueDate = dueDate,
                TaskAssignedTo = assignedTo,
            };

            _tasksList.Add(task);
            return true;
        }

        public bool DeleteTask(Guid taskId)
        {
            var task = _tasksList.FirstOrDefault(t => t.TaskId.Equals(taskId));

            if (task != null)
            {
                _tasksList.Remove(task);
                return true;
            }

            return false;
        }

        public TaskModel? GetTaskById(Guid taskId)
        {
            var task = _tasksList.FirstOrDefault(t => t.TaskId.Equals(taskId));

            return task;
        }

        public List<TaskModel> GetTasksByCreator(string createdBy)
        {
            var tasks = _tasksList.Where(t => t.TaskCreatedBy.Equals(createdBy)).OrderByDescending(o => o.TaskCreatedOn).ToList();

            return tasks;
        }

        public bool MarkTaskCompleted(Guid taskId)
        {
            var task = _tasksList.FirstOrDefault(t => t.TaskId.Equals(taskId));

            if (task != null)
            {
                task.IsCompleted = true;
                return true;
            }

            return false;
        }

        public bool UpdateTask(Guid taskId, string taskName, string assignedTo, DateTime dueDate)
        {
            var task = _tasksList.FirstOrDefault(t => t.TaskId.Equals(taskId));

            if (task != null)
            {
                task.TaskName = taskName;
                task.TaskAssignedTo = assignedTo;
                task.TaskDueDate = dueDate;
                return true;
            }

            return false;
        }
    }
}

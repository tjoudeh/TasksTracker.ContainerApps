using Microsoft.AspNetCore.Mvc;
using TasksTracker.TasksManager.Backend.Api.Models;
using TasksTracker.TasksManager.Backend.Api.Services;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace TasksTracker.TasksManager.Backend.Api.Controllers
{
    [Route("api/tasks")]
    [ApiController]
    public class TasksController : ControllerBase
    {
        private readonly ILogger<TasksController> _logger;
        private readonly ITasksManager _tasksManager;

        public TasksController(ILogger<TasksController> logger, ITasksManager tasksManager)
        {
            _logger = logger;
            _tasksManager = tasksManager;
        }

        [HttpGet]
        public IEnumerable<TaskModel> Get(string createdBy)
        {
            return _tasksManager.GetTasksByCreator(createdBy);
        }

        [HttpGet("{taskId}")]
        public IActionResult Get(Guid taskId)
        {
            var task = _tasksManager.GetTaskById(taskId);
            if (task != null)
            {
                return Ok(_tasksManager.GetTaskById(taskId));
            }

            return NotFound();
           
        }

        [HttpPost]
        public IActionResult Post([FromBody] TaskAddModel taskAddModel)
        {
            var created = _tasksManager.CreateNewTask(taskAddModel.TaskName, 
                            taskAddModel.TaskCreatedBy, 
                            taskAddModel.TaskAssignedTo, 
                            taskAddModel.TaskDueDate);
            if (created)
            {
                return Ok();
            }

            return BadRequest();
        }

        [HttpPut("{taskId}")]
        public IActionResult Put(Guid taskId, [FromBody] TaskUpdateModel taskUpdateModel)
        {
            var updated = _tasksManager.UpdateTask(taskUpdateModel.TaskId,
                            taskUpdateModel.TaskName,
                            taskUpdateModel.TaskAssignedTo,
                            taskUpdateModel.TaskDueDate);
            if (updated)
            {
                return Ok();
            }

            return BadRequest();
        }

        [HttpPut("{taskId}/markcomplete")]
        public IActionResult MarkComplete(Guid taskId)
        {
            var updated = _tasksManager.MarkTaskCompleted(taskId);

            if (updated)
            {
                return Ok();
            }

            return BadRequest();
        }

        [HttpDelete("{taskId}")]
        public IActionResult Delete(Guid taskId)
        {
            var deleted = _tasksManager.DeleteTask(taskId);
            if (deleted)
            {
                return Ok();
            }

            return NotFound();
        }
    }
}

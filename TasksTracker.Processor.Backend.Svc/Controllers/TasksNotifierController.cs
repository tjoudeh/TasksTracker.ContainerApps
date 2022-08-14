using Dapr.Client;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using TasksTracker.Processor.Backend.Svc.Models;

namespace TasksTracker.Processor.Backend.Svc.Controllers
{
    [Route("api/tasksnotifier")]
    [ApiController]
    public class TasksNotifierController : ControllerBase
    {
        public IActionResult Get()
        {
            return Ok();
        }

        [Dapr.Topic("taskspubsub", "tasksavedtopic")]
        [HttpPost("tasksaved")]
        public IActionResult TaskSaved([FromBody]TaskModel taskModel)
        {
            return Ok(taskModel);
        }
    }
}

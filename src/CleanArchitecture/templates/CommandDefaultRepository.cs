using EfCore.Repositories;
using Microsoft.Extensions.Logging;
using Sample.Infrastructure.Persistence.EfCore;

namespace Sample.Infrastructure.Repositories;

public class CommandDefaultRepository(ApplicationDbContext dbContext, ILogger<CommandDefaultRepository> logger)
    : CommandRepository(dbContext, logger)
{ }

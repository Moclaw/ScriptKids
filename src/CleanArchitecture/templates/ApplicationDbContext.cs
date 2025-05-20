using EfCore;
using Microsoft.EntityFrameworkCore;
using Sample.Infrastructure.Persistence.EfCore.Configurations;
using System.Reflection;

namespace Sample.Infrastructure.Persistence.EfCore
{
    public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : BaseDbContext(options)
    {
        protected override Assembly ExecutingAssembly => typeof(ApplicationDbContext).Assembly;

        protected override Func<Type, bool> RegisterConfigurationsPredicate =>
            t => t.Namespace == typeof(ConfigurationFilter).Namespace;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
        }
    }
}

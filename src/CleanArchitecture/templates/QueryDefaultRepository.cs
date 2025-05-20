using EfCore.Repositories;
using Sample.Infrastructure.Persistence.EfCore;
using Shared.Entities;

namespace Sample.Infrastructure.Repositories;
public class QueryDefaultRepository<TEntity, TKey>(ApplicationDbContext dbContext)
    : QueryRepository<TEntity, TKey>(dbContext)
    where TEntity : class, IEntity<TKey>
    where TKey : IEquatable<TKey>
{
}

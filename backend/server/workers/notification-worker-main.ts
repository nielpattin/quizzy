import '../services/notification-worker'

console.log('Notification worker process started')

process.on('SIGINT', async () => {
  console.log('Shutting down notification worker...')
  process.exit(0)
})

process.on('SIGTERM', async () => {
  console.log('Shutting down notification worker...')
  process.exit(0)
})

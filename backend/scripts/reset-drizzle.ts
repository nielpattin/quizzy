import { readdirSync, unlinkSync, writeFileSync } from 'fs'
import { join } from 'path'

const resetDrizzleMigrations = () => {
  console.log('🧹 Resetting Drizzle migration files...')

  const drizzleDir = join(process.cwd(), 'drizzle')
  const metaDir = join(drizzleDir, 'meta')
  const journalPath = join(metaDir, '_journal.json')

  try {
    const journalContent = {
      version: '7',
      dialect: 'postgresql',
      entries: []
    }
    writeFileSync(journalPath, JSON.stringify(journalContent, null, 2), 'utf-8')
    console.log('✓ Reset _journal.json')

    const metaFiles = readdirSync(metaDir)
    let deletedMetaCount = 0
    for (const file of metaFiles) {
      if (file !== '_journal.json' && file.endsWith('.json')) {
        unlinkSync(join(metaDir, file))
        deletedMetaCount++
      }
    }
    console.log(`✓ Deleted ${deletedMetaCount} snapshot files from meta/`)

    const drizzleFiles = readdirSync(drizzleDir)
    let deletedSqlCount = 0
    for (const file of drizzleFiles) {
      if (file.endsWith('.sql')) {
        unlinkSync(join(drizzleDir, file))
        deletedSqlCount++
      }
    }
    console.log(`✓ Deleted ${deletedSqlCount} SQL migration files`)

    console.log('✅ Drizzle migrations reset complete!')
  } catch (error) {
    console.error('❌ Failed to reset Drizzle migrations:', error)
    process.exit(1)
  }
}

resetDrizzleMigrations()

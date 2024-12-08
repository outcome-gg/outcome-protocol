local ConfiguratorNotices = {}

function ConfiguratorNotices.stageUpdateNotice(process, action, tags, data, hash, timestamp, msg)
  msg.reply({
    Action = 'Update-Staged',
    UpdateProcess = process,
    UpdateAction = action,
    UpdateTags = tags,
    UpdateData = data,
    Hash = hash,
    Timestamp = timestamp,
  })
end

function ConfiguratorNotices.unstageUpdateNotice(hash, msg)
  msg.reply({
    Action = 'Update-Unstaged',
    Hash = hash
  })
end

function ConfiguratorNotices.actionUpdateNotice(hash, msg)
  msg.reply({
    Action = 'Update-Actioned',
    Hash = hash
  })
end

function ConfiguratorNotices.stageUpdateAdminNotice(admin, hash, timestamp, msg)
  msg.reply({
    Action = 'Update-Admin-Staged',
    UpdateAdmin = admin,
    Hash = hash,
    Timestamp = timestamp,
  })
end

function ConfiguratorNotices.unstageUpdateAdminNotice(hash, msg)
  msg.reply({
    Action = 'Update-Admin-Unstaged',
    Hash = hash
  })
end

function ConfiguratorNotices.actionUpdateAdminNotice(hash, msg)
  msg.reply({
    Action = 'Update-Admin-Actioned',
    Hash = hash
  })
end

function ConfiguratorNotices.stageUpdateDelayNotice(delay, hash, timestamp, msg)
  msg.reply({
    Action = 'Update-Delay-Staged',
    UpdateDelay = delay,
    Hash = hash,
    Timestamp = timestamp,
  })
end

function ConfiguratorNotices.unstageUpdateDelayNotice(hash, msg)
  msg.reply({
    Action = 'Update-Delay-Unstaged',
    Hash = hash
  })
end

function ConfiguratorNotices.actionUpdateDelayNotice(hash, msg)
  msg.reply({
    Action = 'Update-Delay-Actioned',
    Hash = hash
  })
end

return ConfiguratorNotices
export const getMessageData = (messages) => {
    let target = messages[messages.length -1].Target;
    let data = messages[messages.length -1].Data;
    let tags = Object.assign({}, ...messages[messages.length -1]['Tags'].map((x) => ({[x.name]: x.value})));
    return { target, data, tags };
}

export const getMessagesData = (messages) => {
    let target_array = []
    let data_array = []
    let tags_array = []
    for (let i = 0; i < messages.length; i++) {
        let target = messages[i].Target;
        let data = messages[i].Data;
        let tags = Object.assign({}, ...messages[i]['Tags'].map((x) => ({[x.name]: x.value})));
        target_array.push(target)
        data_array.push(data)
        tags_array.push(tags)
    }
    return { target_array, data_array, tags_array };
}

export const getOutputData = (output) => {
    let data = ''
    if (typeof(output["data"]) == 'string') {
        data = output["data"]
    } else {
        data = output["data"]["output"]
    }
    return { data }
}

export const getNoticeAction = (message) => {
    return message.split('Action = \x1B[34m')[1].split('\x1B[0m')[0]
}

export const parseNoticeData = (x) => {
    if (x.node.Messages.length > 0) {
        return getMessagesData(x.node.Messages)
    } else {
        return getOutputData(x.node.Output)
    } 
}

export const getNoticeData = (results) => {
    let res = results["edges"]
        .map((x) => parseNoticeData(x))   
    return res
}
  
export const getErrorMessage = (error) => {
    return error.split(":")[4].trim()
}

export const parseAmount = (amount, denomination, isNegative=false) => {
    amount = (amount * Math.pow(10, denomination)).toString();
    return isNegative ? '-' + amount : amount;
}

export const parseBalances = (data) => {
    return JSON.parse(data)
}

export const delay = ms => new Promise(res => setTimeout(res, ms));


export function transformAllUserData(data) {
    const transformed = {};

    for (const category in data) {
        if (Array.isArray(data[category])) {
            continue; // Skip categories that are empty arrays
        } else {
            const userEntries = (data[category]);
            for (const userId in userEntries) {
                if (!transformed[userId]) {
                    transformed[userId] = {
                        total: 0,
                        defi: 0,
                        memes: 0,
                        technology: 0,
                        ao: 0,
                        games: 0,
                        business: 0
                    };
                }
                const value = parseInt(userEntries[userId], 10);
                transformed[userId][category] = isNaN(value) ? 0 : value;
            }
        }
    }
    // Calculate the total for each user
    for (const userId in transformed) {
        const userBalances = transformed[userId];
        userBalances.total = Object.values(userBalances).reduce((acc, num) => acc + num, 0) - userBalances.total;
    }

    return transformed;
}

export const calculateRankedUsers = (currentWagerBalances, category) => {
    let users = Object.keys(currentWagerBalances);
    let sortedUsers = (category == 'all') ? 
      users.sort((a, b) => currentWagerBalances[b]?.total - currentWagerBalances[a]?.total) :
      users.sort((a, b) => currentWagerBalances[b][category] - currentWagerBalances[a][category])
      let rankedUsers = sortedUsers.map((user, idx) => {
      return {
        user: user,
        total: currentWagerBalances[user].total,
        defi: currentWagerBalances[user].defi,
        memes: currentWagerBalances[user].memes,
        technology: currentWagerBalances[user].technology,
        ao: currentWagerBalances[user].ao,
        games: currentWagerBalances[user].games,
        business: currentWagerBalances[user].business,
      }
    })
    return rankedUsers
  }

// module.exports = { 
//     getMessageData, 
//     getNoticeData, 
//     getNoticeAction, 
//     getErrorMessage, 
//     parseAmount, 
//     parseBalances,
//     delay,
//     calculateRankedUsers,
//     transformAllUserData
// }
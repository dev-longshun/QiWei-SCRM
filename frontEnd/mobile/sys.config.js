/**
 * 环境变量
 */
const ORIGIN =
  typeof window !== 'undefined' && window.location ? window.location.origin : ''

const envs = {
  development: {
    DOMAIN: 'http://127.0.0.1:8085', // 站点域名，会根据此处域名判断应用环境
    BASE_URL: '/openmobile/', // 路由基础路径
    BASE_API: 'http://127.0.0.1:8085', // 接口基础路径
  },
  // 同 pc/sys.config.ts：production 作为兜底，DOMAIN/BASE_API 取运行时 origin，
  // 一份产物同时适用 http://IP 与 https://域名。
  production: {
    DOMAIN: ORIGIN,
    BASE_URL: '/openmobile/',
    BASE_API: ORIGIN + '/iyque',
  },
}

const packMode = globalThis.MODE || import.meta.env.MODE
const mode =
  process.env.NODE_ENV == 'development' || !globalThis.document
    ? packMode // 本地开发和vite中使用
    : Object.keys(envs).find((e) => envs[e].DOMAIN === window?.location.origin) || 'production' // 打包后，根据访问域名动态判断环境

const BASE_URL = envs[packMode].BASE_URL
const env = envs[mode] || {}

// 配置项
export const config = {
  ...env,
  SYSTEM_NAME: '源雀', // 系统简称
}
Object.assign(config, { BASE_URL, RUN_ENV: mode })

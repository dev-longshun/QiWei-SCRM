// 环境变量
// 构建期在 Node 里跑（无 window），ORIGIN 为空字符串，只影响不被使用的字段；
// 浏览器里为实际访问源。
const ORIGIN =
  typeof window !== 'undefined' && window.location ? window.location.origin : ''

const envs = {
  development: {
    DOMAIN: 'http://127.0.0.1:8085',
    BASE_URL: '/tools/',
    BASE_API: 'http://127.0.0.1:8085',
  },
  test: {
    DOMAIN: 'https://show.iyque.cn',
    BASE_URL: '/tools/',
    BASE_API: 'https://show.iyque.cn/iyque',
  },
  // production 作为兜底环境：DOMAIN 取运行时 origin，因此任何非 development/test
  // 的访问地址都会命中这里。BASE_API 同源拼接，所以同一份产物在
  // http://IP（备案期间）和 https://域名（备案后）都能跑，无需重新打包。
  // 注意必须是绝对地址：mobile/src/views/chat/detail.vue 会用正则从中抠主机名。
  production: {
    DOMAIN: ORIGIN,
    BASE_URL: '/tools/',
    BASE_API: ORIGIN + '/iyque',
  },
}

let mode =
  process.env.NODE_ENV == 'development' || !globalThis.document
    ? process.env.VUE_APP_ENV
    : Object.keys(envs).find((e) => envs[e].DOMAIN === window?.location.origin)

export const env = { ...envs[mode], ENV: mode }

// 系统常量配置
export const common = {
  SYSTEM_NAME: '源雀', // 系统简称
  SYSTEM_SLOGAN:
    '<a href="https://www.iyque.cn?utm_source=iyquecode" target="_blank">源雀Scrm-是基于Java源码交付的企微SCRM,帮助企业构建高度自由安全的私域平台.</a> ', // 系统标语
  COPYRIGHT: 'Copyright © 2022-2025 源雀 All Rights Reserved.', // 版权信息
  LOGO: env.BASE_URL + 'static/logo.png', // 深色logo
}

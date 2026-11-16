import { createContext, useContext, type ReactNode } from "react";

import type { BeefTVConnectionSummary } from "@/services/api/beeftv-connection";

/**
 * 本地版本：官方账号/设备码授权/钱包入口已整体移除。
 *
 * 这里保留组件与 hook 的导出契约（返回值结构不变），但改为纯本地空实现：
 *  - 不请求 /api/beeftv/connection/*，不做 30 秒轮询；
 *  - 连接状态恒为 disconnected；
 *  - 所有 connect / disconnect / 钱包等操作均为空操作。
 *
 * 这样既切断了联网与登录入口，也避免改动所有调用点造成编译失败。
 * 后端 internal/beeftv 包本身仍保留，生成与媒体逻辑继续依赖它。
 */

const DISCONNECTED: BeefTVConnectionSummary = { state: "disconnected" };

const noop = async (): Promise<BeefTVConnectionSummary> => DISCONNECTED;

type ConnectionValue = {
    connection: BeefTVConnectionSummary | null;
    busy: boolean;
    loading: boolean;
    syncing: boolean;
    balanceRefreshFailed: boolean;
    catalogSyncFailed: boolean;
    connect: () => Promise<BeefTVConnectionSummary>;
    cancel: () => Promise<BeefTVConnectionSummary>;
    disconnect: () => Promise<BeefTVConnectionSummary>;
    refresh: () => Promise<BeefTVConnectionSummary>;
    refreshBalance: () => Promise<void>;
    getMutationSeq: () => number;
    applySummary: (summary: BeefTVConnectionSummary) => void;
    applyBalanceCnyIfCurrent: (expectedSeq: number, balanceCny: string) => boolean;
    retryCatalog: () => Promise<BeefTVConnectionSummary>;
    openAccount: () => Promise<void>;
};

const LOCAL_CONNECTION: ConnectionValue = {
    connection: DISCONNECTED,
    busy: false,
    loading: false,
    syncing: false,
    balanceRefreshFailed: false,
    catalogSyncFailed: false,
    connect: noop,
    cancel: noop,
    disconnect: noop,
    refresh: noop,
    refreshBalance: async () => undefined,
    getMutationSeq: () => 0,
    applySummary: () => undefined,
    applyBalanceCnyIfCurrent: () => false,
    retryCatalog: noop,
    openAccount: async () => undefined,
};

const BeefTVConnectionContext = createContext<ConnectionValue>(LOCAL_CONNECTION);

export function BeefTVConnectionProvider({ children }: { children: ReactNode }) {
    return <BeefTVConnectionContext.Provider value={LOCAL_CONNECTION}>{children}</BeefTVConnectionContext.Provider>;
}

export function useBeefTVConnection(): ConnectionValue {
    return useContext(BeefTVConnectionContext);
}

// import { useMemo, useState, useEffect } from "react";
// import { useNavigate } from "react-router-dom";
// import {
//   Sun,
//   Moon,
//   Clock,
//   AlertCircle,
//   CheckCheck,
//   ChevronRight,
//   PauseCircle,
//   PlayCircle,
// } from "lucide-react";

// import AppShell from "@/layouts/AppShell";
// import { useAuth } from "@/context/AuthContext";
// import { getTheme, setTheme, resolvedTheme } from "@/lib/theme";

// import { Avatar } from "@/components/ui/Avatar";
// import { IconCircleButton } from "@/components/ui/IconCircleButton";
// import { BottomTabBar } from "@/components/ui/BottomTabBar";
// import { FloatingFab } from "@/components/ui/FloatingFab";
// import { CreateSheet } from "@/components/CreateSheet";
// import { BellOutlineIcon } from "@/components/icons/TabBarIcons";
// import { StatNoteCard } from "@/components/dashboard/StatNoteCard";

// import { type StubTicket } from "@/lib/stubs/tickets";
// import { useTickets } from "@/context/TicketsContext";
// import { useCreateTicketEntry } from "@/hooks/useCreateTicketEntry";
// import { filterTicketsByAccess, getDefaultViewMode } from "@/lib/roleAccess";
// import { NotificationsSheet } from "@/components/NotificationsSheet";
// import { useNotifications } from "@/context/NotificationsContext";

// /**
//  * Severity ranking (lower = more urgent). Drives the order of items in the
//  * Needs Attention list and the visual chip color.
//  */
// type Severity = "overdue" | "due_soon" | "not_started" | "needs_ack";
// type AttentionItem = {
//   ticket: StubTicket;
//   /** Minutes value used for chip display + secondary sort. */
//   minutes: number;
//   severity: Severity;
// };

// /** Thresholds (minutes) for the attention classifier. */
// const NEEDS_ACK_AFTER_MIN = 5;
// const NOT_STARTED_AFTER_MIN = 5;
// const DUE_SOON_WITHIN_MIN = 10;

// function minutesSince(iso?: string, nowMs = Date.now()): number {
//   if (!iso) return 0;
//   const t = new Date(iso).getTime();
//   if (Number.isNaN(t)) return 0;
//   return Math.max(0, Math.floor((nowMs - t) / 60_000));
// }

// function minutesUntil(iso?: string, nowMs = Date.now()): number {
//   if (!iso) return Number.POSITIVE_INFINITY;
//   const t = new Date(iso).getTime();
//   if (Number.isNaN(t)) return Number.POSITIVE_INFINITY;
//   return Math.ceil((t - nowMs) / 60_000);
// }

// export default function Dashboard() {
//   const { user } = useAuth();
//   const navigate = useNavigate();
//   const { tickets } = useTickets();
//   const { createSheetOpen, openCreateSheet, closeCreateSheet, handleSelect } =
//     useCreateTicketEntry();
//   const { unreadCount } = useNotifications();
//   const [notificationsOpen, setNotificationsOpen] = useState(false);
//   const [themeTick, setThemeTick] = useState(0);
//   const isDark = themeTick >= 0 && resolvedTheme() === "dark";

//   // Tick every 30s so live timing thresholds (overdue / due-soon / waiting)
//   // stay current without us manually subscribing per-ticket.
//   const [, setNowTick] = useState(0);
//   useEffect(() => {
//     const id = setInterval(() => setNowTick((n) => n + 1), 30_000);
//     return () => clearInterval(id);
//   }, []);

//   // Tickets visible to this user under their default scope.
//   const visibleTickets = useMemo(() => {
//     if (!user) return [] as StubTicket[];
//     return filterTicketsByAccess(
//       tickets,
//       user,
//       getDefaultViewMode(user.role),
//       [],
//       user.role === "staff" && user.departments.length > 0
//         ? user.departments[0]
//         : null,
//     );
//   }, [user, tickets]);

//   // ── Lifecycle-based slices for the KPI cards ──
//   const incoming = useMemo(
//     () =>
//       visibleTickets.filter(
//         (t) => (t.lifecycleStatus ?? "new") === "new",
//       ),
//     [visibleTickets],
//   );
//   const accepted = useMemo(
//     () =>
//       visibleTickets.filter((t) => t.lifecycleStatus === "accepted"),
//     [visibleTickets],
//   );
//   const inProgress = useMemo(
//     () =>
//       visibleTickets.filter((t) => t.lifecycleStatus === "in_progress"),
//     [visibleTickets],
//   );
//   const overdue = useMemo(
//     () => {
//       const nowMs = Date.now();
//       return visibleTickets.filter((t) => {
//         if (t.lifecycleStatus !== "in_progress") return false;
//         if (!t.dueAt) return false;
//         return new Date(t.dueAt).getTime() <= nowMs;
//       });
//     },
//     // eslint-disable-next-line react-hooks/exhaustive-deps
//     [visibleTickets],
//   );

//   const incomingUniversal = incoming.filter((t) => t.type === "universal").length;
//   const incomingPaid = incoming.filter((t) => t.type === "paid").length;
//   const incomingManual = incoming.filter((t) => t.type === "manual").length;

//   // ── Needs Attention classifier ──
//   // Operational flags only: overdue, due soon, accepted-but-not-started,
//   // and new-tickets-waiting-too-long. Capped at 5 entries — Dashboard is
//   // a briefing, not a full list.
//   const needsAttention = useMemo<AttentionItem[]>(() => {
//     const nowMs = Date.now();
//     const items: AttentionItem[] = visibleTickets
//       .map<AttentionItem | null>((t) => {
//         const ls = t.lifecycleStatus ?? "new";

//         // 1. Overdue (in_progress + dueAt passed)
//         if (ls === "in_progress" && t.dueAt) {
//           const overdueMin = minutesSince(t.dueAt, nowMs);
//           if (new Date(t.dueAt).getTime() <= nowMs) {
//             return { ticket: t, minutes: overdueMin, severity: "overdue" };
//           }
//           // 2. Due soon — within threshold
//           const remaining = minutesUntil(t.dueAt, nowMs);
//           if (remaining >= 0 && remaining <= DUE_SOON_WITHIN_MIN) {
//             return { ticket: t, minutes: remaining, severity: "due_soon" };
//           }
//           return null;
//         }

//         // 3. Accepted but not started (no startedAt) past threshold
//         if (ls === "accepted") {
//           const since = minutesSince(t.acceptedAt, nowMs);
//           if (!t.startedAt && since >= NOT_STARTED_AFTER_MIN) {
//             return { ticket: t, minutes: since, severity: "not_started" };
//           }
//           return null;
//         }

//         // 4. New ticket waiting too long
//         if (ls === "new") {
//           const since = minutesSince(t.createdAt, nowMs);
//           if (since >= NEEDS_ACK_AFTER_MIN) {
//             return { ticket: t, minutes: since, severity: "needs_ack" };
//           }
//           return null;
//         }

//         return null;
//       })
//       .filter((x): x is AttentionItem => x !== null)
//       .sort((a, b) => {
//         const order: Record<Severity, number> = {
//           overdue: 0,
//           due_soon: 1,
//           not_started: 2,
//           needs_ack: 3,
//         };
//         if (order[a.severity] !== order[b.severity])
//           return order[a.severity] - order[b.severity];
//         // Within overdue/needs_ack/not_started: largest minutes first.
//         // Within due_soon: smallest minutes first (most urgent).
//         if (a.severity === "due_soon") return a.minutes - b.minutes;
//         return b.minutes - a.minutes;
//       })
//       .slice(0, 5);
//     return items;
//   }, [visibleTickets]);

//   // Greeting
//   const now = new Date();
//   const hour = now.getHours();
//   const greeting =
//     hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening";
//   const dateString = now.toLocaleDateString("en-US", { weekday: "long" });
//   const timeString = now.toLocaleTimeString("en-US", {
//     hour: "numeric",
//     minute: "2-digit",
//   });
//   const showDeptHint =
//     user?.role === "staff" && user?.departments.length === 1;
//   const deptHint = showDeptHint && user ? ` · ${user.departments[0]}` : "";

//   const toggleTheme = () => {
//     const current = getTheme();
//     const resolved = resolvedTheme();
//     if (current === "system") {
//       setTheme(resolved === "dark" ? "light" : "dark");
//     } else {
//       setTheme(current === "dark" ? "light" : "dark");
//     }
//     setThemeTick((t) => t + 1);
//   };

//   if (!user) return null;

//   const overdueVariant: "zero" | "warning" | "danger" =
//     overdue.length === 0
//       ? "zero"
//       : overdue.length >= 3
//         ? "danger"
//         : "warning";

//   const breakdownText = [
//     incomingUniversal > 0 && `${incomingUniversal} universal`,
//     incomingPaid > 0 && `${incomingPaid} paid`,
//     incomingManual > 0 && `${incomingManual} manual`,
//   ]
//     .filter(Boolean)
//     .join(" · ");

//   const hasNotificationDot = incoming.length > 0 || overdue.length > 0;

//   return (
//     <AppShell>
//       <div className="relative flex h-screen-safe flex-col bg-[rgb(var(--bg-subtle))] overflow-hidden">
//         <div className="shrink-0 bg-[rgb(var(--bg-subtle))] overflow-hidden">
//           {/* HEADER */}
//           <div className="flex items-center justify-between gap-3 px-4 pt-[max(env(safe-area-inset-top),12px)] pb-3">
//           <Avatar
//             name={user.name}
//             size="lg"
//             color="neutral"
//             onClick={() => navigate("/profile")}
//             ariaLabel="Open profile"
//           />
//           <div className="flex items-center gap-2 shrink-0">
//             <IconCircleButton
//               icon={isDark ? <Sun size={18} /> : <Moon size={18} />}
//               onClick={toggleTheme}
//               ariaLabel="Toggle theme"
//             />
//             <IconCircleButton
//               icon={<BellOutlineIcon width={18} height={18} />}
//               onClick={() => setNotificationsOpen(true)}
//               ariaLabel="Notifications"
//               dot={unreadCount > 0 || hasNotificationDot}
//             />
//           </div>
//           </div>

//           {/* GREETING */}
//           <div className="px-4 pb-4 flex flex-col gap-1">
//           <h1 className="text-title text-[rgb(var(--fg-base))]">
//             {greeting}, {user.name.split(" ")[0]}
//           </h1>
//           <p className="text-meta text-[rgb(var(--fg-muted))]">
//             {dateString} · {timeString}
//             {deptHint}
//           </p>
//           </div>
//         </div>

//         <div className="flex-1 min-h-0 overflow-y-auto overscroll-contain pb-[156px]">
//           {/* STATS GRID — operational KPIs, each routes to the matching tab/filter */}
//           <div className="px-4 pb-5 grid grid-cols-2 gap-2.5">
//           {/* Big card — Incoming / Needs Acknowledgment */}
//           <StatNoteCard
//             tone="neutral"
//             badgeLabel="NEEDS ACKNOWLEDGMENT"
//             value={incoming.length}
//             footer={breakdownText || "Awaiting acceptance"}
//             size="lg"
//             onClick={() =>
//               navigate("/tickets", { state: { initialTab: "incoming" } })
//             }
//             ariaLabel={`${incoming.length} incoming tickets — view incoming`}
//             className="col-span-2"
//             trailing={<ChevronRight size={18} />}
//           />

//           {/* In Progress */}
//           <StatNoteCard
//             tone="purple"
//             badgeLabel="IN PROGRESS"
//             value={inProgress.length}
//             footer="Currently being worked on"
//             size="md"
//             onClick={() =>
//               navigate("/tickets", {
//                 state: { initialTab: "today", initialTodayFilter: "in_progress" },
//               })
//             }
//             ariaLabel={`${inProgress.length} tickets in progress — view in-progress`}
//           />

//           {/* Overdue */}
//           <StatNoteCard
//             tone={
//               overdueVariant === "danger"
//                 ? "red"
//                 : overdueVariant === "warning"
//                   ? "orange"
//                   : "neutral"
//             }
//             badgeLabel="OVERDUE"
//             value={overdue.length}
//             footer={overdue.length === 0 ? "Past due time" : "Past due time"}
//             size="md"
//             onClick={() =>
//               navigate("/tickets", {
//                 state: { initialTab: "today", initialTodayFilter: "overdue" },
//               })
//             }
//             ariaLabel={`${overdue.length} overdue tickets — view overdue`}
//           />

//           {/* Accepted / Not Started */}
//           <StatNoteCard
//             tone={accepted.length > 0 ? "blue" : "neutral"}
//             badgeLabel="NOT STARTED"
//             value={accepted.length}
//             footer="Accepted but not started"
//             size="md"
//             onClick={() =>
//               navigate("/tickets", {
//                 state: { initialTab: "today", initialTodayFilter: "accepted" },
//               })
//             }
//             ariaLabel={`${accepted.length} accepted but not started — view accepted`}
//             className="col-span-2"
//           />
//         </div>

//         {/* SECTION HEADER */}
//         <div className="px-4 pb-2 flex items-center justify-between">
//           <h2 className="text-heading text-[rgb(var(--fg-base))]">
//             Needs attention
//           </h2>
//           {needsAttention.length > 0 && (
//             <button
//               type="button"
//               onClick={() =>
//                 navigate("/tickets", { state: { initialTab: "today" } })
//               }
//               className="text-caption font-medium text-[rgb(var(--tag-purple-icon))] touch-manipulation"
//             >
//               View all
//             </button>
//           )}
//         </div>

//         {/* NEEDS ATTENTION LIST */}
//         <div className="px-4">
//           {needsAttention.length === 0 ? (
//             <div className="flex flex-col items-center justify-center text-center py-10 gap-3">
//               <div className="h-12 w-12 rounded-full bg-[rgb(var(--tag-green-bg))] flex items-center justify-center text-[rgb(var(--tag-green-icon))]">
//                 <CheckCheck size={22} />
//               </div>
//               <div className="flex flex-col gap-1">
//                 <span className="text-body-strong text-[rgb(var(--fg-base))]">
//                   All clear
//                 </span>
//                 <span className="text-meta text-[rgb(var(--fg-muted))]">
//                   No tickets need immediate attention right now.
//                 </span>
//                 <span className="text-caption text-[rgb(var(--fg-subtle))] mt-0.5">
//                   New and active tickets are available in the Tickets tab.
//                 </span>
//               </div>
//             </div>
//           ) : (
//             <div className="flex flex-col gap-2">
//               {needsAttention.map(({ ticket: t, minutes, severity }) => {
//                 const palette =
//                   severity === "overdue"
//                     ? {
//                         iconBg:
//                           "bg-[rgb(var(--tag-red-bg))] text-[rgb(var(--tag-red-icon))]",
//                         pill:
//                           "bg-[rgb(var(--tag-red-bg))] text-[rgb(var(--tag-red-text))]",
//                       }
//                     : severity === "due_soon"
//                       ? {
//                           iconBg:
//                             "bg-[rgb(var(--tag-orange-bg))] text-[rgb(var(--tag-orange-icon))]",
//                           pill:
//                             "bg-[rgb(var(--tag-orange-bg))] text-[rgb(var(--tag-orange-text))]",
//                         }
//                       : severity === "not_started"
//                         ? {
//                             iconBg:
//                               "bg-[rgb(var(--tag-blue-bg))] text-[rgb(var(--tag-blue-icon))]",
//                             pill:
//                               "bg-[rgb(var(--tag-blue-bg))] text-[rgb(var(--tag-blue-text))]",
//                           }
//                         : {
//                             iconBg:
//                               "bg-[rgb(var(--tag-neutral-bg))] text-[rgb(var(--tag-neutral-text))]",
//                             pill:
//                               "bg-[rgb(var(--tag-neutral-bg))] text-[rgb(var(--tag-neutral-text))]",
//                           };
//                 const pillLabel =
//                   severity === "overdue"
//                     ? `Overdue ${minutes}m`
//                     : severity === "due_soon"
//                       ? `Due in ${Math.max(0, minutes)}m`
//                       : severity === "not_started"
//                         ? "Not started"
//                         : `Waiting ${minutes}m`;
//                 const Icon =
//                   severity === "overdue"
//                     ? AlertCircle
//                     : severity === "due_soon"
//                       ? Clock
//                       : severity === "not_started"
//                         ? PauseCircle
//                         : PlayCircle;
//                 const subParts = [
//                   t.room ? `Room ${t.room}` : null,
//                   t.department,
//                 ].filter(Boolean);
//                 return (
//                   <button
//                     key={t.id}
//                     type="button"
//                     onClick={() => navigate(`/tickets/${t.id}`)}
//                     className="
//                       flex items-center gap-3
//                       px-3.5 py-3 rounded-xl
//                       bg-[rgb(var(--bg-base))]
//                       shadow-[0_1px_2px_rgba(0,0,0,0.04),0_0_0_1px_rgba(0,0,0,0.04)]
//                       text-left transition-transform duration-100 active:scale-[0.99]
//                       touch-manipulation
//                     "
//                   >
//                     <div
//                       className={`shrink-0 h-9 w-9 rounded-full flex items-center justify-center ${palette.iconBg}`}
//                     >
//                       <Icon size={18} />
//                     </div>
//                     <div className="flex-1 min-w-0 flex flex-col gap-0.5">
//                       <span className="text-body-strong text-[rgb(var(--fg-base))] truncate">
//                         {t.title}
//                       </span>
//                       <span className="text-meta text-[rgb(var(--fg-muted))] truncate">
//                         {subParts.join(" · ")}
//                       </span>
//                     </div>
//                     <span
//                       className={`shrink-0 inline-flex items-center gap-1 px-2 py-1 rounded-full text-caption font-medium ${palette.pill}`}
//                       style={{ fontVariantNumeric: "tabular-nums" }}
//                     >
//                       {pillLabel}
//                     </span>
//                   </button>
//                 );
//               })}
//             </div>
//           )}
//           </div>
//         </div>

//         {/* FAB + NAV */}
//         <FloatingFab
//           onClick={openCreateSheet}
//           ariaLabel="Create new ticket"
//         />
//         <BottomTabBar
//           activeTab="dashboard"
//           onTabChange={(tab) => {
//             if (tab === "tickets") navigate("/tickets");
//             else if (tab === "profile") navigate("/profile");
//           }}
//         />

//         <CreateSheet
//           open={createSheetOpen}
//           onClose={closeCreateSheet}
//           onSelect={handleSelect}
//         />

//         <NotificationsSheet
//           open={notificationsOpen}
//           onClose={() => setNotificationsOpen(false)}
//           onSelect={(n) => {
//             setNotificationsOpen(false);
//             navigate(`/tickets/${n.ticketId}`);
//           }}
//         />
//       </div>
//     </AppShell>
//   );
// }

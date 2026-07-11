/**
 * In-memory versus lobby for 2-player online battles.
 * Host-authoritative turn relay during battle.
 */

const rooms = new Map();

function makeCode() {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < 6; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return rooms.has(code) ? makeCode() : code;
}

function send(ws, msg) {
  if (ws && ws.readyState === 1) ws.send(JSON.stringify(msg));
}

function broadcast(room, msg) {
  send(room.host, msg);
  if (room.guest) send(room.guest, msg);
}

function roomPayload(room) {
  return {
    code: room.code,
    status: room.status,
    team_size: room.team_size,
    level: room.level,
    host_name: room.host_name,
    guest_name: room.guest_name || "",
    host_ready: room.host_ready,
    guest_ready: room.guest_ready,
    host_team_count: room.host_team.length,
    guest_team_count: room.guest_team.length,
    has_guest: !!room.guest,
  };
}

function findRoomBySocket(ws) {
  for (const room of rooms.values()) {
    if (room.host === ws || room.guest === ws) return room;
  }
  return null;
}

function teamOk(team, size) {
  return Array.isArray(team) && team.length === size && team.every((id) => typeof id === "string" && id.length > 0);
}

function startBattle(room) {
  room.status = "battle";
  send(room.host, {
    type: "battle_start",
    role: "host",
    host_name: room.host_name,
    guest_name: room.guest_name,
    team_size: room.team_size,
    level: room.level,
    host_team: room.host_team,
    guest_team: room.guest_team,
  });
  send(room.guest, {
    type: "battle_start",
    role: "guest",
    host_name: room.host_name,
    guest_name: room.guest_name,
    team_size: room.team_size,
    level: room.level,
    host_team: room.host_team,
    guest_team: room.guest_team,
  });
}

function maybeStart(room) {
  if (
    room.guest &&
    room.host_ready &&
    room.guest_ready &&
    teamOk(room.host_team, room.team_size) &&
    teamOk(room.guest_team, room.team_size)
  ) {
    startBattle(room);
  }
}

function handleMessage(ws, raw) {
  let msg;
  try {
    msg = JSON.parse(raw);
  } catch {
    send(ws, { type: "error", message: "Bad JSON" });
    return;
  }

  switch (msg.type) {
    case "create_room": {
      const existing = findRoomBySocket(ws);
      if (existing) return;
      const code = makeCode();
      const room = {
        code,
        host: ws,
        guest: null,
        host_name: String(msg.name || "Host").slice(0, 16),
        guest_name: "",
        team_size: 3,
        level: 15,
        host_team: [],
        guest_team: [],
        host_ready: false,
        guest_ready: false,
        status: "lobby",
        pending_guest_action: null,
      };
      rooms.set(code, room);
      ws._roomCode = code;
      ws._role = "host";
      send(ws, { type: "room_state", room: roomPayload(room) });
      break;
    }
    case "join_room": {
      const code = String(msg.code || "").toUpperCase().trim();
      const room = rooms.get(code);
      if (!room) {
        send(ws, { type: "error", message: "Room not found" });
        return;
      }
      if (room.guest) {
        send(ws, { type: "error", message: "Room is full" });
        return;
      }
      room.guest = ws;
      room.guest_name = String(msg.name || "Guest").slice(0, 16);
      room.status = "draft";
      ws._roomCode = code;
      ws._role = "guest";
      broadcast(room, { type: "room_state", room: roomPayload(room) });
      break;
    }
    case "set_options": {
      const room = findRoomBySocket(ws);
      if (!room || ws._role !== "host") return;
      const size = Number(msg.team_size);
      const level = Number(msg.level);
      if ([1, 3].includes(size)) room.team_size = size;
      if ([10, 15, 20].includes(level)) room.level = level;
      room.host_team = [];
      room.guest_team = [];
      room.host_ready = false;
      room.guest_ready = false;
      broadcast(room, { type: "room_state", room: roomPayload(room) });
      break;
    }
    case "set_team": {
      const room = findRoomBySocket(ws);
      if (!room) return;
      const team = Array.isArray(msg.echo_ids) ? msg.echo_ids.map(String) : [];
      if (!teamOk(team, room.team_size)) {
        send(ws, { type: "error", message: `Pick exactly ${room.team_size} Echoes` });
        return;
      }
      if (ws._role === "host") room.host_team = team;
      else room.guest_team = team;
      if (ws._role === "host") room.host_ready = false;
      else room.guest_ready = false;
      broadcast(room, { type: "room_state", room: roomPayload(room) });
      break;
    }
    case "ready": {
      const room = findRoomBySocket(ws);
      if (!room) return;
      if (ws._role === "host") room.host_ready = true;
      else room.guest_ready = true;
      broadcast(room, { type: "room_state", room: roomPayload(room) });
      maybeStart(room);
      break;
    }
    case "guest_action": {
      const room = findRoomBySocket(ws);
      if (!room || ws._role !== "guest" || room.status !== "battle") return;
      room.pending_guest_action = msg.action || null;
      send(room.host, { type: "guest_action", action: room.pending_guest_action });
      break;
    }
    case "turn_result": {
      const room = findRoomBySocket(ws);
      if (!room || ws._role !== "host" || room.status !== "battle") return;
      room.pending_guest_action = null;
      send(room.guest, {
        type: "turn_result",
        log: msg.log || [],
        state: msg.state || {},
        finished: !!msg.finished,
        winner: String(msg.winner || ""),
      });
      break;
    }
    case "battle_end": {
      const room = findRoomBySocket(ws);
      if (!room || ws._role !== "host") return;
      room.status = "ended";
      send(room.guest, { type: "battle_end", winner: String(msg.winner || "") });
      break;
    }
    default:
      send(ws, { type: "error", message: "Unknown message" });
  }
}

function handleClose(ws) {
  const room = findRoomBySocket(ws);
  if (!room) return;
  if (room.host === ws) {
    if (room.guest) send(room.guest, { type: "error", message: "Host disconnected" });
    rooms.delete(room.code);
  } else if (room.guest === ws) {
    room.guest = null;
    room.guest_name = "";
    room.guest_team = [];
    room.guest_ready = false;
    room.status = "lobby";
    send(room.host, { type: "room_state", room: roomPayload(room) });
  }
}

module.exports = { handleMessage, handleClose };

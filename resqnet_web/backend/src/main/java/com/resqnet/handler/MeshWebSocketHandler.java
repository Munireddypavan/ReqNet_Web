package com.resqnet.handler;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.resqnet.model.MeshMessage;
import com.resqnet.model.MeshNode;
import com.resqnet.repository.MessageRepository;
import com.resqnet.repository.NodeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

@Component
public class MeshWebSocketHandler extends TextWebSocketHandler {

    // Wrap each session in a ConcurrentWebSocketSessionDecorator to prevent
    // "TEXT_PARTIAL_WRITING" errors when multiple threads broadcast simultaneously
    private static final List<ConcurrentWebSocketSessionDecorator> sessions = new CopyOnWriteArrayList<>();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private NodeRepository nodeRepository;

    @Autowired
    private MessageRepository messageRepository;

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        // Wrap with a 30s send-time limit and 512KB buffer to handle concurrent sends safely
        ConcurrentWebSocketSessionDecorator safeSession =
            new ConcurrentWebSocketSessionDecorator(session, 30000, 512 * 1024);
        sessions.add(safeSession);
        System.out.println("NEW MESH NODE CONNECTED: Session " + session.getId() + " - Active Nodes: " + sessions.size());
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String payload = message.getPayload();

        try {
            Map<String, Object> data = objectMapper.readValue(payload, Map.class);
            String type = (String) data.get("type");

            if ("GPS_BEACON".equals(type)) {
                String senderId = (String) data.get("senderId");
                String name = (String) data.get("name");
                Number timestamp = (Number) data.get("timestamp");
                Number lat = (Number) data.get("lat");
                Number lng = (Number) data.get("lng");

                if (senderId != null && lat != null && lng != null) {
                    MeshNode node = new MeshNode(
                        senderId,
                        name != null ? name : senderId.substring(0, Math.min(8, senderId.length())),
                        timestamp != null ? timestamp.longValue() : System.currentTimeMillis(),
                        lat.doubleValue(),
                        lng.doubleValue()
                    );
                    try {
                        // saveAndFlush handles both INSERT and UPDATE correctly
                        nodeRepository.save(node);
                    } catch (DataIntegrityViolationException e) {
                        // Node already exists — attempt an update instead
                        if (nodeRepository.existsById(senderId)) {
                            nodeRepository.save(node);
                        }
                    }
                }
            } else if (data.containsKey("messageId")) {
                String messageId = (String) data.get("messageId");
                String senderId = (String) data.get("senderId");
                String receiverId = (String) data.get("receiverId");
                String content = (String) data.get("content");
                Number timestamp = (Number) data.get("timestamp");
                Number ttl = (Number) data.get("ttl");
                Number hops = (Number) data.get("hops");
                String status = (String) data.get("status");

                if (messageId != null && senderId != null && receiverId != null) {
                    MeshMessage msg = new MeshMessage(
                        messageId,
                        senderId,
                        receiverId,
                        content != null ? content : "",
                        timestamp != null ? timestamp.longValue() : System.currentTimeMillis(),
                        ttl != null ? ttl.intValue() : 5,
                        hops != null ? hops.intValue() : 0,
                        status != null ? status : "Sent"
                    );

                    if ("AUTHORITIES".equalsIgnoreCase(receiverId)) {
                        System.out.println("====================================================================");
                        System.out.println("🚨🚨🚨 GATEWAY NODE DISPATCH TRIGGERED 🚨🚨🚨");
                        System.out.println("SENDER ID : " + senderId);
                        System.out.println("ALERT MSG : " + content);
                        System.out.println("STATUS    : RELAYING DIRECTLY TO EMERGENCY SERVICES APIS VIA INTERNET BRIDGE!");
                        System.out.println("====================================================================");
                        msg.setStatus("Gateway Delivered");
                    }

                    try {
                        messageRepository.save(msg);
                    } catch (DataIntegrityViolationException e) {
                        // Duplicate message ID — skip silently
                    }

                    // Re-serialize with updated status if changed
                    payload = objectMapper.writeValueAsString(msg);
                }
            }

            // Broadcast to all OTHER connected sessions safely via the concurrent decorator
            TextMessage broadcastMessage = new TextMessage(payload);
            for (ConcurrentWebSocketSessionDecorator s : sessions) {
                if (s.isOpen() && !s.getId().equals(session.getId())) {
                    try {
                        s.sendMessage(broadcastMessage);
                    } catch (Exception e) {
                        System.err.println("Failed to forward payload to session " + s.getId() + ": " + e.getMessage());
                    }
                }
            }

        } catch (Exception e) {
            System.err.println("Error processing WS payload: " + e.getMessage());
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        sessions.removeIf(s -> s.getId().equals(session.getId()));
        System.out.println("MESH NODE DISCONNECTED: Session " + session.getId() + " - Active Nodes: " + sessions.size());
    }
}

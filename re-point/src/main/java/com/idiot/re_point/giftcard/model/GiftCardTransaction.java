package com.idiot.re_point.giftcard.model;

import com.google.cloud.Timestamp;
import lombok.*;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Getter @Setter
@Builder
@AllArgsConstructor @NoArgsConstructor
public class GiftCardTransaction {
    private String id;
    private String uid;
    private int amount;
    private String code;
    private Instant issuedAt;

    public static GiftCardTransaction fromMap(String id, Map<String, Object> m) {
        if (m == null) return null;

        GiftCardTransaction.GiftCardTransactionBuilder b = GiftCardTransaction.builder()
                .id(id)
                .uid((String) m.getOrDefault("uid", ""))
                .amount(((Number) m.getOrDefault("amount", 0)).intValue())
                .code((String) m.getOrDefault("code", ""));

        Object ia = m.get("issued_at");
        if (ia instanceof Timestamp ts) {
            b.issuedAt(ts.toDate().toInstant());
        } else if (ia instanceof String s && !s.isEmpty()) {
            try { b.issuedAt(Instant.parse(s)); } catch (Exception ignored) {}
        }

        return b.build();
    }

    public Map<String, Object> toMap() {
        Map<String, Object> map = new HashMap<>();
        if (uid != null) map.put("uid", uid);
        map.put("amount", amount);
        if (code != null) map.put("code", code);
        map.put("issued_at",
                issuedAt == null ? null :
                        Timestamp.ofTimeSecondsAndNanos(issuedAt.getEpochSecond(), issuedAt.getNano()));
        return map;
    }
    public static String generateGiftCardCode() {
        return UUID.randomUUID().toString().replaceAll("-", "").substring(0, 16).toUpperCase();
    }
}

// com.idiot.re_point.giftcard.model.Giftcard.java
package com.idiot.re_point.giftcard.model;

import com.google.cloud.Timestamp;
import lombok.*;
import java.util.HashMap;
import java.util.Map;

@Getter @Setter @Builder
@AllArgsConstructor @NoArgsConstructor
public class Giftcard {
    private String cardId;     // "card_5000"
    private String cardName;   // "지역상품권 5천원권"
    private long   cardValue;  // 5000, 10000 ...
    private long   stock;      // 재고
    private boolean active;    // 판매 여부

    public Map<String,Object> toMap() {
        Map<String,Object> m = new HashMap<>();
        m.put("card_name", cardName);
        m.put("card_value", cardValue);
        m.put("stock", stock);
        m.put("active", active);
        m.put("created_at", Timestamp.now());
        return m;
    }
}
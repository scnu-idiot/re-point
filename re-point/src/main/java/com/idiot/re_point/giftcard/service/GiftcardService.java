package com.idiot.re_point.giftcard.service;

import com.google.cloud.Timestamp;
import com.google.cloud.firestore.CollectionReference;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.idiot.re_point.giftcard.dto.GiftcardDto;
import com.idiot.re_point.giftcard.model.GiftCardTransaction;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
@RequiredArgsConstructor
public class GiftcardService {

    private final Firestore firestore;

    private CollectionReference giftcardCol() {
        return firestore.collection("giftcards");
    }

    private CollectionReference historyCol() {
        return firestore.collection("exchanges");
    }


    public List<GiftcardDto> listActive() throws ExecutionException, InterruptedException {
        List<QueryDocumentSnapshot> docs = giftcardCol()
                .whereEqualTo("active", true)
                .get().get().getDocuments();

        List<GiftcardDto> out = new ArrayList<>(docs.size());
        for (QueryDocumentSnapshot d : docs) {
            out.add(GiftcardDto.builder()
                    .cardId(d.getId())
                    .cardName(d.getString("card_name"))
                    .cardValue(d.getLong("card_value") == null ? 0L : d.getLong("card_value"))
                    .active(Boolean.TRUE.equals(d.getBoolean("active")))
                    .stock(d.getLong("stock") == null ? 0L : d.getLong("stock"))
                    .build());
        }
        // 프론트에서 정렬이 필요하면 여기서 cardValue asc 정렬 등 추가 가능
        return out;
    }

    public List<GiftCardTransaction> listTransactions(String uid) throws ExecutionException, InterruptedException {
        List<QueryDocumentSnapshot> docs = historyCol()
                .whereEqualTo("user_id", uid)
                .orderBy("exchange_date", Query.Direction.DESCENDING)
                .get().get().getDocuments();

        List<GiftCardTransaction> out = new ArrayList<>(docs.size());
        for (QueryDocumentSnapshot d : docs) {
            Map<String, Object> data = d.getData();
            Map<String, Object> deliveryInfo = (Map<String, Object>) data.get("delivery_info");
            String code = deliveryInfo != null ? (String) deliveryInfo.get("code") : null;

            GiftCardTransaction tx = GiftCardTransaction.builder()
                    .id(d.getId())
                    .uid((String) data.get("user_id"))
                    .amount(((Number) data.getOrDefault("card_value", 0)).intValue())
                    .code(code)
                    .issuedAt(((Timestamp) data.get("exchange_date")).toDate().toInstant())
                    .build();
            out.add(tx);
        }
        return out;
    }
}

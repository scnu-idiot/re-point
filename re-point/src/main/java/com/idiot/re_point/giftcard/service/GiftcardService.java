package com.idiot.re_point.giftcard.service;

import com.google.cloud.firestore.CollectionReference;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.idiot.re_point.giftcard.dto.GiftcardDto;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

@Service
@RequiredArgsConstructor
public class GiftcardService {

    private final Firestore firestore;

    private CollectionReference col() {
        return firestore.collection("giftcards");
    }

    public List<GiftcardDto> listActive() throws ExecutionException, InterruptedException {
        List<QueryDocumentSnapshot> docs = col()
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
}
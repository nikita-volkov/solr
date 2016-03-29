module Solr.Request where

import Solr.Prelude
import qualified Solr.HTTPResponseDecoder
import qualified Solr.HTTPRequestEncoder
import qualified Solr.Parameters
import qualified Solr.JSONEncoder
import qualified Solr.JSONDecoder
import qualified ByteString.TreeBuilder


-- |
-- Solr request specification.
data Request a b =
  Request
    !(ByteString -> Solr.HTTPRequestEncoder.Request a)
    !(Solr.HTTPResponseDecoder.Response b)

instance Functor (Request a) where
  {-# INLINE fmap #-}
  fmap f (Request requestEncoderProducer responseDecoder) =
    Request requestEncoderProducer (fmap f responseDecoder)

instance Profunctor Request where
  {-# INLINE dimap #-}
  dimap f1 f2 (Request requestEncoderProducer responseDecoder) =
    Request ((fmap . contramap) f1 requestEncoderProducer) (fmap f2 responseDecoder)


select :: Solr.JSONEncoder.Select a -> Solr.JSONDecoder.Select b -> Request a b
select selectEncoder selectDecoder =
  Request requestEncoderProducer responseDecoder
  where
    requestEncoderProducer baseURL =
      Solr.HTTPRequestEncoder.request_postJSON url jsonEncoder
      where
        url =
          baseURL <> "select/?wt=json"
        jsonEncoder =
          Solr.JSONEncoder.value_select selectEncoder
    responseDecoder =
      Solr.HTTPResponseDecoder.json $
      Solr.JSONDecoder.value_select $
      selectDecoder

update :: Solr.JSONEncoder.Update a -> Request a ()
update updateEncoder =
  Request requestEncoderProducer responseDecoder
  where
    requestEncoderProducer baseURL =
      Solr.HTTPRequestEncoder.request_postJSON url jsonEncoder
      where
        url =
          baseURL <> "update/?commit=true"
        jsonEncoder =
          Solr.JSONEncoder.value_update updateEncoder
    responseDecoder =
      Solr.HTTPResponseDecoder.okay
